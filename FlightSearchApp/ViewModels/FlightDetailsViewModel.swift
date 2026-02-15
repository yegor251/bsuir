import Foundation
import Combine

final class FlightDetailsViewModel: ObservableObject {
    @Published var flight: Flight
    @Published var isSaved: Bool
    @Published var notes: String
    @Published var title: String
    @Published var notes2: String

    private let databaseService: DatabaseServiceProtocol

    init(flight: Flight, isSaved: Bool = false, notes: String = "", title: String = "", notes2: String = "", databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
        self.flight = flight
        self.isSaved = isSaved
        self.notes = notes
        self.title = title
        self.notes2 = notes2
        self.databaseService = databaseService
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

    private func save() {
        try? databaseService.saveFlight(flight, notes: notes.isEmpty ? nil : notes, title: title.isEmpty ? nil : title, notes2: notes2.isEmpty ? nil : notes2)
    }

    private func delete() {
        try? databaseService.deleteFlight(id: flight.id)
    }
}
