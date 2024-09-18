import SwiftUI

struct TimetableView: View {
    let stop: StopWithDirections
    let direction: Direction

    var body: some View {
        VStack {
            Text("Timetable for \(stop.name) to \(direction.to)")
                .font(.headline)
                .padding()

            List(direction.entries) { entry in
                VStack(alignment: .leading) {
                    Text("\(entry.category) \(entry.number) to \(entry.to)")
                        .font(.headline)
                    Text("Departure: \(formatDate(entry.stop.departure))")
                        .font(.subheadline)
                }
            }

            Spacer()

            Button(action: {
                // Dismiss the view
            }) {
                Text("Close")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
    }

    func formatDate(_ dateString: String) -> String {
        // Convert ISO8601 date string to a user-friendly format
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        if let date = isoFormatter.date(from: dateString) {
            return dateFormatter.string(from: date)
        } else {
            return dateString
        }
    }
}
