import Foundation
import MapKit

struct Route: Identifiable, Equatable {
    let id: UUID
    let name: String
    let startPoint: CLLocationCoordinate2D
    let endPoint: CLLocationCoordinate2D
    let distance: Double
    let estimatedTime: TimeInterval

    static func == (lhs: Route, rhs: Route) -> Bool {
        return lhs.id == rhs.id
    }
}
