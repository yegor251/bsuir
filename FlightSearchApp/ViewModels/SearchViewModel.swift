import Foundation
import Combine

final class SearchViewModel: ObservableObject {
    @Published var query = SearchQuery()
    @Published var flights: [Flight] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let flightService: MockFlightServiceProtocol
    private let databaseService: DatabaseServiceProtocol

    init(
        flightService: MockFlightServiceProtocol = MockFlightService.shared,
        databaseService: DatabaseServiceProtocol = DatabaseService.shared
    ) {
        self.flightService = flightService
        self.databaseService = databaseService
    }

    func search() {
        errorMessage = nil

        guard validateInput() else {
            errorMessage = LocalizationService.shared.localizedString("error_invalid_input")
            return
        }

        isLoading = true
        flightService.searchFlights(query: query) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
                switch result {
                case .success(let flights):
                    self.flights = flights
                    if flights.isEmpty {
                        self.errorMessage = LocalizationService.shared.localizedString("error_no_results")
                    }
                case .failure(let error):
                    self.flights = []
                    switch error {
                    case MockFlightError.invalidInput:
                        self.errorMessage = LocalizationService.shared.localizedString("error_invalid_input")
                    case MockFlightError.noResults:
                        self.errorMessage = LocalizationService.shared.localizedString("error_no_results")
                    default:
                        self.errorMessage = LocalizationService.shared.localizedString("error_generic")
                    }
                }
            }
        }
    }

    func saveFlight(_ flight: Flight) {
        do {
            try databaseService.saveFlight(flight, notes: nil, title: nil, notes2: nil)
        } catch {
            errorMessage = LocalizationService.shared.localizedString("error_save_failed")
        }
    }

    private func validateInput() -> Bool {
        guard !query.origin.trimmingCharacters(in: .whitespaces).isEmpty,
              !query.destination.trimmingCharacters(in: .whitespaces).isEmpty else {
            return false
        }
        return true
    }
}
