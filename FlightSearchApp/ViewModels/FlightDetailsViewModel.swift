import Foundation
import Combine
import FirebaseFirestore

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
        do {
            try databaseService.saveFlight(flight, notes: notes.isEmpty ? nil : notes, title: title.isEmpty ? nil : title, notes2: notes2.isEmpty ? nil : notes2)
            
            syncToFirebase()
        } catch {
            print("Ошибка локального сохранения: \(error)")
        }
    }
    
    private func syncToFirebase() {
        let db = Firestore.firestore()
        let docId = flight.id.uuidString
        
        let flightData: [String: Any] = [
            "id": flight.id.uuidString,
            "airline": flight.airline,
            "arrivalDate": flight.arrivalDate,
            "departureDate": flight.departureDate,
            "destination": flight.destination,
            "flightNumber": flight.flightNumber,
            "notes": notes,
            "notes2": notes2,
            "origin": flight.origin,
            "price": flight.price,
            "title": title,
            "lastUpdated": FieldValue.serverTimestamp()
        ]
        
        db.collection("saved_flights").document(docId).setData(flightData, merge: true) { error in
            if let error = error {
                print("Ошибка синхронизации с Firebase: \(error.localizedDescription)")
            } else {
                print("Рейс успешно синхронизирован с Firebase")
            }
        }
    }

    private func delete() {
        try? databaseService.deleteFlight(id: flight.id)
    }
}

