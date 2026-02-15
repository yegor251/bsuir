import Foundation

protocol MockFlightServiceProtocol {
    func searchFlights(query: SearchQuery, completion: @escaping (Result<[Flight], Error>) -> Void)
}

enum MockFlightError: Error {
    case invalidInput
    case noResults
}

private struct FlightTemplate: Decodable {
    let airline: String
    let flightNumber: String
    let origin: String
    let destination: String
    let departureDate: String
    let departureTime: String
    let durationMinutes: Int
    let price: Double
    let layovers: [String]
}

final class MockFlightService: MockFlightServiceProtocol {
    static let shared = MockFlightService()

    private let resourceName = "flights"
    private let resourceExtension = "json"

    private init() {}

    func searchFlights(query: SearchQuery, completion: @escaping (Result<[Flight], Error>) -> Void) {
        guard !query.origin.trimmingCharacters(in: .whitespaces).isEmpty,
              !query.destination.trimmingCharacters(in: .whitespaces).isEmpty else {
            completion(.failure(MockFlightError.invalidInput))
            return
        }

        DispatchQueue.global().async { [self] in
            let result = loadAndSearch(query: query)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    private func loadAndSearch(query: SearchQuery) -> Result<[Flight], Error> {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension),
              let data = try? Data(contentsOf: url) else {
            return .failure(MockFlightError.noResults)
        }

        let decoder = JSONDecoder()
        guard let templates = try? decoder.decode([FlightTemplate].self, from: data) else {
            return .failure(MockFlightError.noResults)
        }

        let originNorm = query.origin.trimmingCharacters(in: .whitespaces).uppercased()
        let destinationNorm = query.destination.trimmingCharacters(in: .whitespaces).uppercased()
        
        let calendar = Calendar.current
        let queryDay = calendar.startOfDay(for: query.departureDate)

        let matching = templates.filter { template in
            guard template.origin.uppercased() == originNorm,
                  template.destination.uppercased() == destinationNorm else {
                return false
            }
            guard let templateDate = parseDate(template.departureDate, calendar: calendar) else {
                return false
            }
            let templateDay = calendar.startOfDay(for: templateDate)
            return calendar.isDate(templateDay, inSameDayAs: queryDay)
        }

        if matching.isEmpty {
            return .failure(MockFlightError.noResults)
        }

        let flights: [Flight] = matching.compactMap { template in
            guard let departureDate = combine(date: query.departureDate, timeString: template.departureTime, calendar: calendar) else {
                return nil as Flight?
            }
            let arrivalDate = calendar.date(byAdding: .minute, value: template.durationMinutes, to: departureDate) ?? departureDate

            return Flight(
                airline: template.airline,
                flightNumber: template.flightNumber,
                origin: template.origin.uppercased(),
                destination: template.destination.uppercased(),
                departureDate: departureDate,
                arrivalDate: arrivalDate,
                durationMinutes: template.durationMinutes,
                price: template.price,
                layovers: template.layovers
            )
        }.sorted { $0.departureDate < $1.departureDate }

        return .success(flights)
    }

    private func parseDate(_ dateString: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        return formatter.date(from: dateString)
    }

    private func combine(date: Date, timeString: String, calendar: Calendar) -> Date? {
        let parts = timeString.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]),
              (0...23).contains(hour),
              (0...59).contains(minute) else {
            return nil
        }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)
    }
}
