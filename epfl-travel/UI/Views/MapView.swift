import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var stopsWithDirections: [StopWithDirections]
    @Binding var bikeStops: [BikeStop]
    @Binding var forceUpdate: Bool
    var showsUserLocation: Bool
    var onRegionChange: (MKCoordinateRegion) -> Void
    var onStopsRequest: (CLLocationCoordinate2D, Double) -> Void
    var onStopClick: (StopWithDirections, Direction) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showsUserLocation
        mapView.mapType = .mutedStandard
        mapView.setRegion(region, animated: true)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if forceUpdate {
            uiView.setRegion(region, animated: true)
        }

        // Efficiently update annotations
        let existingAnnotations = uiView.annotations
        uiView.removeAnnotations(existingAnnotations)

        var newAnnotations: [MKPointAnnotation] = []

        // Add Transport Stops with Directions (max 2 per stop)
        for stop in stopsWithDirections {
            let baseCoordinate = CLLocationCoordinate2D(latitude: stop.coordinate.x!, longitude: stop.coordinate.y!)
            let offsetDistance = 0.00005
            for (index, direction) in stop.directions.enumerated() {
                guard index < 2 else { break } // Ensure at most 2 directions
                let annotation = MKPointAnnotation()
                annotation.title = stop.name
                annotation.subtitle = direction.to
                // Offset the coordinate slightly to prevent overlap
                let offsetLatitude = baseCoordinate.latitude + (Double(index) * offsetDistance)
                let offsetLongitude = baseCoordinate.longitude + (Double(index % 2) * offsetDistance)
                annotation.coordinate = CLLocationCoordinate2D(latitude: offsetLatitude, longitude: offsetLongitude)
                newAnnotations.append(annotation)
            }
        }
        uiView.addAnnotations(newAnnotations)

        // Add Bike Stops (unchanged)
        let bikeAnnotations = bikeStops.map { stop -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = stop.name
            annotation.subtitle = "bike"
            annotation.coordinate = CLLocationCoordinate2D(latitude: stop.latitude, longitude: stop.longitude)
            return annotation
        }
        uiView.addAnnotations(bikeAnnotations)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, onRegionChange: onRegionChange, onStopsRequest: onStopsRequest, onStopClick: onStopClick)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var onRegionChange: (MKCoordinateRegion) -> Void
        var onStopsRequest: (CLLocationCoordinate2D, Double) -> Void
        var onStopClick: (StopWithDirections, Direction) -> Void
        private var regionChangeTimer: Timer?

        init(_ parent: MapView, onRegionChange: @escaping (MKCoordinateRegion) -> Void, onStopsRequest: @escaping (CLLocationCoordinate2D, Double) -> Void, onStopClick: @escaping (StopWithDirections, Direction) -> Void) {
            self.parent = parent
            self.onRegionChange = onRegionChange
            self.onStopsRequest = onStopsRequest
            self.onStopClick = onStopClick
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            regionChangeTimer?.invalidate()
            regionChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                let center = mapView.centerCoordinate
                let radius = self.getRadius(of: mapView)
                if radius <= 1000 {
                    self.onStopsRequest(center, radius)
                }
                self.onRegionChange(mapView.region)
            }
        }

        func getRadius(of mapView: MKMapView) -> Double {
            let centerLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            let topCenterCoordinate = mapView.convert(CGPoint(x: mapView.frame.size.width / 2.0, y: 0), toCoordinateFrom: mapView)
            let topCenterLocation = CLLocation(latitude: topCenterCoordinate.latitude, longitude: topCenterCoordinate.longitude)
            return centerLocation.distance(from: topCenterLocation)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKPointAnnotation {
                let identifier = "StopAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.frame = CGRect(x: 0, y: 0, width: 34, height: 34)
                    annotationView?.layer.cornerRadius = 17
                } else {
                    annotationView?.annotation = annotation
                }

                annotationView?.backgroundColor = UIColor(white: 1.0, alpha: 0.9)
                annotationView?.layer.borderColor = UIColor.gray.cgColor
                annotationView?.layer.borderWidth = 3
                return annotationView
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKPointAnnotation,
                  let stopName = annotation.title,
                  let directionTo = annotation.subtitle else { return }

            // Find the corresponding stop and direction
            if let stopWithDirections = parent.stopsWithDirections.first(where: { $0.name == stopName }) {
                if let direction = stopWithDirections.directions.first(where: { $0.to == directionTo }) {
                    
                    // Print passList for each vehicle in the direction
                    for entry in direction.entries {
                        print("Vehicle \(entry.number) to \(entry.to):")

                        if let passList = entry.passList {
                            // Print the first stop, checking if it's unknown
                            if let firstStopName = passList.first?.station.name {
                                print("\tStop 1: \(firstStopName)")
                            } else {
                                print("\tStop 1: \(stopWithDirections.name) (Current Stop)")  // Use the current stop name
                            }

                            // Print the remaining stops
                            for (index, stopDetail) in passList.dropFirst().enumerated() {
                                print("\tStop \(index + 2): \(stopDetail.station.name ?? "Unknown")")
                            }
                        } else {
                            print("\tNo passList available for this vehicle")
                        }
                    }
                    
                    // Proceed with the existing onStopClick action
                    onStopClick(stopWithDirections, direction)
                }
            }
        }
    }
}
