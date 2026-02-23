import SwiftUI

struct SavedFlightsView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    @StateObject private var viewModel = SavedFlightsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let message = viewModel.errorMessage {
                    Text(message)
                        .foregroundColor(.secondary)
                        .padding()
                } else if viewModel.flights.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text(localizationService.localizedString("saved_empty_state"))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.flights) { flight in
                            NavigationLink {
                                let flightModel = Flight(
                                    id: flight.id,
                                    airline: flight.airline,
                                    flightNumber: flight.flightNumber,
                                    origin: flight.origin,
                                    destination: flight.destination,
                                    departureDate: flight.departureDate,
                                    arrivalDate: flight.arrivalDate,
                                    durationMinutes: Int(flight.arrivalDate.timeIntervalSince(flight.departureDate) / 60),
                                    price: flight.price
                                )
                                FlightDetailsView(
                                    flight: flightModel,
                                    isSaved: true,
                                    notes: flight.notes ?? "",
                                    title: flight.title ?? "",
                                    notes2: flight.notes2 ?? ""
                                )
                            } label: {
                                SavedFlightRowView(flight: flight)
                            }
                        }
                        .onDelete(perform: viewModel.delete)
                    }
                    .refreshable {
                        viewModel.load()
                    }
                }
            }
            .navigationTitle(localizationService.localizedString("saved_title"))
            .onAppear {
                viewModel.load()
            }
        }
    }
}

struct SavedFlightRowView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    let flight: SavedFlightModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(displayTitle)
                    .font(.headline)
                Spacer()
                Text(priceString)
                    .font(.subheadline)
            }
            Text("\(flight.origin) → \(flight.destination)")
                .font(.subheadline)
            Text(savedDateString)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var displayTitle: String {
        if let t = flight.title, !t.isEmpty {
            return t
        }
        return "\(flight.airline) \(flight.flightNumber)"
    }

    private var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.locale = localizationService.currentLocale
        return "$\(formatter.string(from: NSNumber(value: flight.price)) ?? "\(flight.price)")"
    }

    private var savedDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: flight.savedDate)
    }
}

#Preview {
    SavedFlightsView()
        .environmentObject(LocalizationService.shared)
}
