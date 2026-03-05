import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

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
    private var firestoreListener: ListenerRegistration?

    init(databaseService: DatabaseServiceProtocol = DatabaseService.shared) {
        self.databaseService = databaseService
        load()
        startRealtimeUpdates()

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

    deinit {
        firestoreListener?.remove()
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

    private func startRealtimeUpdates() {
        let db = Firestore.firestore()
        firestoreListener = db.collection("saved_flights")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                let currentFlights = self.flights
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    DispatchQueue.main.async {
                        self.flights = []
                        self.filterFlights()
                        self.isLoading = false
                    }
                    return
                }

                let remoteFlights: [SavedFlightModel] = documents.compactMap { doc in
                    let data = doc.data()

                    let idString = (data["id"] as? String) ?? doc.documentID
                    guard let uuid = UUID(uuidString: idString) else {
                        return nil
                    }

                    let existing = currentFlights.first(where: { $0.id == uuid })

                    let flightNumber = (data["flightNumber"] as? String) ?? existing?.flightNumber ?? ""
                    let airline = (data["airline"] as? String) ?? existing?.airline ?? ""
                    let origin = (data["origin"] as? String) ?? existing?.origin ?? ""
                    let destination = (data["destination"] as? String) ?? existing?.destination ?? ""

                    var price: Double
                    if let p = data["price"] as? Double {
                        price = p
                    } else if let p = data["price"] as? NSNumber {
                        price = p.doubleValue
                    } else if let s = data["price"] as? String,
                              let p = Double(s.replacingOccurrences(of: ",", with: ".")) {
                        price = p
                    } else {
                        price = existing?.price ?? 0
                    }

                    let departureDate: Date
                    if let ts = data["departureDate"] as? Timestamp {
                        departureDate = ts.dateValue()
                    } else if let date = data["departureDate"] as? Date {
                        departureDate = date
                    } else {
                        departureDate = existing?.departureDate ?? Date()
                    }

                    let arrivalDate: Date
                    if let ts = data["arrivalDate"] as? Timestamp {
                        arrivalDate = ts.dateValue()
                    } else if let date = data["arrivalDate"] as? Date {
                        arrivalDate = date
                    } else {
                        arrivalDate = existing?.arrivalDate ?? Date()
                    }

                    let savedDate: Date
                    if let ts = data["lastUpdated"] as? Timestamp {
                        savedDate = ts.dateValue()
                    } else if let date = data["lastUpdated"] as? Date {
                        savedDate = date
                    } else {
                        savedDate = existing?.savedDate ?? Date()
                    }

                    let notes = data["notes"] as? String
                    let title = data["title"] as? String
                    let notes2 = data["notes2"] as? String

                    return SavedFlightModel(
                        id: uuid,
                        flightNumber: flightNumber,
                        airline: airline,
                        origin: origin,
                        destination: destination,
                        departureDate: departureDate,
                        arrivalDate: arrivalDate,
                        price: price,
                        savedDate: savedDate,
                        notes: notes,
                        title: title,
                        notes2: notes2
                    )
                }

                DispatchQueue.main.async {
                    self.flights = remoteFlights
                    self.filterFlights()
                    self.isLoading = false
                }
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
