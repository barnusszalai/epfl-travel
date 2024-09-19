import Foundation
import Combine

class TransportAPIService: ObservableObject {
    @Published var stopsWithDirections: [StopWithDirections] = []
    private var stopsCache: [String: [StopWithDirections]] = [:]
    private var stationboardCache: [String: [StationboardEntry]] = [:]
    
    func fetchStops(latitude: Double, longitude: Double) {
        let urlString = "https://transport.opendata.ch/v1/locations?x=\(latitude)&y=\(longitude)&type=station"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for fetching stops")
            return
        }
        
        if let cachedStops = stopsCache["\(latitude),\(longitude)"] {
            DispatchQueue.main.async {
                self.stopsWithDirections = cachedStops
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                print("Error fetching stops: \(String(describing: error))")
                return
            }
            
            do {
                let stopsResponse = try JSONDecoder().decode(StopsResponse.self, from: data)
                let validStops = stopsResponse.stations.filter { $0.coordinate.x != nil && $0.coordinate.y != nil }
                var stopsWithDirections: [StopWithDirections] = []
                
                let group = DispatchGroup()
                
                for stop in validStops {
                    guard let stopId = stop.id else { continue }
                    group.enter()
                    
                    // Fetch the stationboard with the correct station name
                    self.fetchStationboard(for: stopId, stationName: stop.name) { stationboard in
                        let groupedDirections = self.groupDirections(stationboard)
                        let stopWithDirections = StopWithDirections(
                            id: stopId,
                            name: stop.name,
                            coordinate: stop.coordinate,
                            directions: groupedDirections
                        )
                        stopsWithDirections.append(stopWithDirections)
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.stopsWithDirections = stopsWithDirections
                    self.stopsCache["\(latitude),\(longitude)"] = stopsWithDirections
                }
            } catch {
                print("Error decoding stops: \(error)")
            }
        }
        task.resume()
    }
    
    // Existing fetchStationboard function with caching
    func fetchStationboard(for stationId: String, stationName: String, completion: @escaping ([StationboardEntry]) -> Void) {
        if let cachedStationboard = stationboardCache[stationId] {
            completion(cachedStationboard)
            return
        }
        
        let urlString = "https://transport.opendata.ch/v1/stationboard?id=\(stationId)&limit=50"
        guard let url = URL(string: urlString) else {
            print("Invalid URL for stationboard")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                print("Error fetching stationboard data: \(String(describing: error))")
                return
            }
            
            do {
                let response = try JSONDecoder().decode(StationboardResponse.self, from: data)
                
                var updatedStationboard = response.stationboard.map { entry -> StationboardEntry in
                    var modifiedEntry = entry
                    
                    // Remove any unknown stops in the passList (where stop names are nil or empty)
                    if let passList = entry.passList {
                        modifiedEntry.passList = passList.filter { $0.station.name != nil && !$0.station.name!.isEmpty }
                    }
                    
                    // Remove the first stop if it's the same as the current station
                    if let firstStop = modifiedEntry.passList?.first, firstStop.station.name == stationName {
                        modifiedEntry.passList?.removeFirst()
                    }

                    return modifiedEntry
                }
                
                // Cache the modified stationboard
                DispatchQueue.main.async {
                    self.stationboardCache[stationId] = updatedStationboard
                    completion(updatedStationboard)
                }
            } catch {
                print("Error decoding stationboard data: \(error)")
            }
        }
        task.resume()
    }
    
    // New method to group directions
    private func groupDirections(_ stationboard: [StationboardEntry]) -> [Direction] {
        // Group stationboard entries by 'to' field
        let groupedByDestination = Dictionary(grouping: stationboard) { entry -> String in
            // Clean up the destination name to group similar destinations
            return normalizeDestination(entry.to)
        }
        
        // Sort the groups by the number of entries
        let sortedGroups = groupedByDestination.sorted { $0.value.count > $1.value.count }
        
        // Limit to at most 2 groups
        let limitedGroups = sortedGroups.prefix(2)
        
        // Create Direction objects
        let directions = limitedGroups.map { (destination, entries) -> Direction in
            return Direction(to: destination, entries: entries)
        }
        
        return directions
    }
    
    private func normalizeDestination(_ destination: String) -> String {
        // Implement a normalization function to group similar destinations
        // For simplicity, we'll remove any text after a comma and trim whitespace
        let components = destination.components(separatedBy: ",")
        return components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? destination
    }
}
