import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var transportService = TransportAPIService()
    @ObservedObject private var bikeService = BikeAPIService()

    @State private var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.5247, longitude: 6.5690),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var stopsWithDirections: [StopWithDirections] = []
    @State private var bikeStops: [BikeStop] = []
    @State private var forceUpdate = false
    @State private var shouldRecenterToUser = false
    @State private var hasManuallyRecentered = false
    @State private var selectedStopWithDirection: (StopWithDirections, Direction)?
    @State private var isShowingTimetable = false

    var body: some View {
        ZStack {
            MapView(
                region: $region,
                stopsWithDirections: $stopsWithDirections,
                bikeStops: $bikeStops,
                forceUpdate: $forceUpdate,
                showsUserLocation: true,
                onRegionChange: { newRegion in
                    region = newRegion
                    hasManuallyRecentered = true
                },
                onStopsRequest: { centerCoordinate, radius in
                    if radius <= 1000 {
                        transportService.fetchStops(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)
                    }
                },
                onStopClick: { stopWithDirections, direction in
                    selectedStopWithDirection = (stopWithDirections, direction)
                    isShowingTimetable = true
                }
            )
            .onChange(of: transportService.stopsWithDirections) { newStops in
                stopsWithDirections = newStops
            }
            .onAppear {
                locationManager.requestLocationUpdate()
                bikeService.fetchBikeStations()
            }
            .onChange(of: bikeService.bikeStops) { newBikeStops in
                bikeStops = newBikeStops
            }
            .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let userLocation = locationManager.userLocation {
                            region = MKCoordinateRegion(
                                center: userLocation.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                            forceUpdate.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                forceUpdate.toggle()
                            }
                            shouldRecenterToUser = true
                            hasManuallyRecentered = true
                        } else {
                            locationManager.requestLocationUpdate()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onReceive(locationManager.$userLocation) { newLocation in
            if let userLocation = newLocation, shouldRecenterToUser {
                region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
                forceUpdate.toggle()
                shouldRecenterToUser = false
            }
        }
        .sheet(isPresented: $isShowingTimetable) {
            if let (stop, direction) = selectedStopWithDirection {
                TimetableView(stop: stop, direction: direction)
            }
        }
    }
}
