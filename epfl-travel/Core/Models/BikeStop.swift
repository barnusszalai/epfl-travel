
import Foundation

struct BikeStop: Codable, Identifiable, Equatable {
    let id: Int
    let latitude: Double
    let longitude: Double
    let state: BikeStationState?
    let name: String
    let address: String?
    let zip: String?
    let city: String?
    let vehicles: [BikeVehicle]?
    let network: Network?
    let sponsors: [Sponsor]?
    let isVirtualStation: Bool?
    let capacity: Int?

    static func == (lhs: BikeStop, rhs: BikeStop) -> Bool {
        return lhs.id == rhs.id &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.name == rhs.name
    }
}

struct BikeStationState: Codable {
    let id: Int
    let name: String
}

struct BikeVehicle: Codable {
    let id: Int
    let name: String
    let ebikeBatteryLevel: Double?
    let type: VehicleType
}

struct VehicleType: Codable {
    let id: Int
    let name: String
}

struct Network: Codable {
    let id: Int
    let name: String
    let backgroundImg: String?
    let logoImg: String?
    let sponsors: [Sponsor]?
}

struct Sponsor: Codable {
    // Define sponsor properties if needed
}
