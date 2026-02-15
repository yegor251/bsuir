import Foundation
import Combine
import SwiftUI

final class SavedFlightsViewModel: ObservableObject {
    @Published var flights: [SavedFlightModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let databaseService: DatabaseServiceProtocol

    init(databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
        self.databaseService = databaseService
        load()
    }

    func load() {
        isLoading = true
        errorMessage = nil
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                let saved = try self.databaseService.fetchSavedFlights()
                DispatchQueue.main.async {
                    self.flights = saved
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = LocalizationService.shared.localizedString("error_load_saved")
                    self.isLoading = false
                }
            }
        }
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = flights[index]
            try? databaseService.deleteFlight(id: item.id)
        }
        flights.remove(atOffsets: offsets)
    }
}
