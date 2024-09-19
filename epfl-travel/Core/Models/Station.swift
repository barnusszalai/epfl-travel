import Foundation

struct Station: Codable, Equatable {
    let id: String
    let name: String?
    let coordinate: Coordinate?
}
