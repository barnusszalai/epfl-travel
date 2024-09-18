import Foundation
import Combine
import CoreLocation

class BikeAPIService: ObservableObject {
    @Published var bikeStops: [BikeStop] = []
    let lausanneLocation = CLLocation(latitude: 46.5191, longitude: 6.6323)
    func fetchBikeStations() {
        let urlString = "https://api.publibike.ch/v1/public/partner/stations"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                print("Error fetching Publibike stations: \(String(describing: error))")
                return
            }

            do {
                let decoder = JSONDecoder()
                let bikeResponse = try decoder.decode(BikeStationResponse.self, from: data)
                let stationsWithinRadius = bikeResponse.stations.filter { station in
                    let stationLocation = CLLocation(latitude: station.latitude, longitude: station.longitude)
                    let distance = self.lausanneLocation.distance(from: stationLocation) / 1000
                    return distance <= 5
                }

                DispatchQueue.main.async {
                    self.bikeStops = stationsWithinRadius
                }
            } catch {
                print("Error decoding bike stops: \(error)")
            }
        }
        task.resume()
    }
}

struct BikeStationResponse: Codable {
    let stations: [BikeStop]
}
