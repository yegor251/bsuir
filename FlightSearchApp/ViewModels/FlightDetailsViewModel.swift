import Foundation
import Combine

final class FlightDetailsViewModel: ObservableObject {
    @Published var flight: Flight
    @Published var isSaved: Bool
    @Published var notes: String
    @Published var title: String
    @Published var notes2: String
    @Published var temperature: Double?
    @Published var weatherState: WeatherState = .loading

    enum WeatherState {
        case loading
        case loaded
        case offline
        case error
    }

    private let databaseService: DatabaseServiceProtocol
    private let weatherService: WeatherService

    init(
        flight: Flight,
        isSaved: Bool = false,
        notes: String = "",
        title: String = "",
        notes2: String = "",
        databaseService: DatabaseServiceProtocol = DatabaseService.shared,
        weatherService: WeatherService = .shared
    ) {
        self.flight = flight
        self.isSaved = isSaved
        self.notes = notes
        self.title = title
        self.notes2 = notes2
        self.databaseService = databaseService
        self.weatherService = weatherService
    }

    func toggleSaved() {
        if isSaved {
            delete()
        } else {
            save()
        }
        isSaved.toggle()
    }

    func saveUpdates() {
        guard isSaved else { return }
        try? databaseService.updateSavedFlight(id: flight.id, notes: notes.isEmpty ? nil : notes, title: title.isEmpty ? nil : title, notes2: notes2.isEmpty ? nil : notes2)
    }

    func loadWeather() async {
        print("FlightDetailsViewModel.loadWeather start, destination=\(flight.destination)")
        weatherState = .loading
        let city = flight.destination
        let temperatureResult = try? await weatherService.fetchWeather(for: city)
        print("FlightDetailsViewModel.loadWeather temperatureResult=\(String(describing: temperatureResult))")
        await MainActor.run {
            temperature = temperatureResult
            weatherState = temperatureResult != nil ? .loaded : .error
        }
    }

    private func save() {
        try? databaseService.saveFlight(flight, notes: notes.isEmpty ? nil : notes, title: title.isEmpty ? nil : title, notes2: notes2.isEmpty ? nil : notes2)
    }

    private func delete() {
        try? databaseService.deleteFlight(id: flight.id)
    }
}

