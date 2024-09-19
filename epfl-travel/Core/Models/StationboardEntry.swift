import Foundation

struct StationboardEntry: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: String
    let number: String
    let to: String
    let stop: Stop
    var passList: [StopDetail]?  // Change let to var to allow mutation
}

struct StopDetail: Codable, Equatable {
    let station: Station
    let arrival: String?
    let departure: String?
}
