import Foundation
import Combine
import SwiftUI

enum SavedFlightsSortOption: String, CaseIterable {
    case dateAdded = "Date Added"
    case price = "Price"
    case departureDate = "Departure Date"

    var localizationKey: String {
        switch self {
        case .dateAdded: return "saved_sort_date_added"
        case .price: return "saved_sort_price"
        case .departureDate: return "saved_sort_departure_date"
        }
    }
}

final class SavedFlightsViewModel: ObservableObject {
    @Published var flights: [SavedFlightModel] = []
    @Published var searchText: String = ""
    @Published var sortOption: SavedFlightsSortOption = .dateAdded
    @Published var filteredFlights: [SavedFlightModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var destinationFilter: String = ""

    var allSavedFlights: [SavedFlightModel] { flights }

    private let databaseService: DatabaseServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
        self.databaseService = databaseService
        load()

        $searchText
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterFlights()
            }
            .store(in: &cancellables)

        $sortOption
            .sink { [weak self] _ in
                self?.filterFlights()
            }
            .store(in: &cancellables)

        $destinationFilter
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterFlights()
            }
            .store(in: &cancellables)
    }

    func fuzzyMatch(_ query: String, in text: String) -> Bool {
        let q = query
            .lowercased()
            .filter { !$0.isWhitespace }
        let t = text.lowercased()
        if q.isEmpty { return true }

        var tIndex = t.startIndex
        for qc in q {
            var found = false
            while tIndex < t.endIndex {
                if t[tIndex] == qc {
                    found = true
                    tIndex = t.index(after: tIndex)
                    break
                }
                tIndex = t.index(after: tIndex)
            }
            if !found { return false }
        }
        return true
    }

    func filterFlights() {
        var results = flights

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedSearch.isEmpty {
            results = results.filter { flight in
                let title = flight.title ?? ""
                return fuzzyMatch(trimmedSearch, in: title)
            }
        }

        let trimmedDestination = destinationFilter.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedDestination.isEmpty {
            results = results.filter { flight in
                flight.destination.localizedCaseInsensitiveContains(trimmedDestination)
            }
        }

        results = sortFlights(results)
        filteredFlights = results
    }

    func sortFlights(_ flightsToSort: [SavedFlightModel]) -> [SavedFlightModel] {
        switch sortOption {
        case .dateAdded: return flightsToSort.sorted { $0.savedDate > $1.savedDate }
        case .price: return flightsToSort.sorted { $0.price < $1.price }
        case .departureDate: return flightsToSort.sorted { $0.departureDate < $1.departureDate }
        }
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
                    self.filterFlights()
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
        let toDelete = offsets.map { filteredFlights[$0] }
        for flight in toDelete {
            try? databaseService.deleteFlight(id: flight.id)
        }
        flights.removeAll { toDelete.contains($0) }
        filterFlights()
    }
}
