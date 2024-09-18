import Foundation

struct StopWithDirections: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: Coordinate
    let directions: [Direction]
}

struct Direction: Equatable {
    let to: String
    let entries: [StationboardEntry]
}
