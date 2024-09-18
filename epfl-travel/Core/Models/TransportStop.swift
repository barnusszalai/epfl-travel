import Foundation

struct TransportStop: Codable, Identifiable, Equatable {
    let id: String?
    let name: String
    let coordinate: Coordinate
    let icon: String?

    static func == (lhs: TransportStop, rhs: TransportStop) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name && lhs.coordinate == rhs.coordinate
    }
}
