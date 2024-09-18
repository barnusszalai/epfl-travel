import Foundation

struct StationboardEntry: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: String
    let number: String
    let to: String
    let stop: Stop
}
