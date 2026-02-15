import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text(localizationService.localizedString("search_route"))) {
                        TextField(localizationService.localizedString("origin_placeholder"), text: $viewModel.query.origin)
                        TextField(localizationService.localizedString("destination_placeholder"), text: $viewModel.query.destination)

                        DatePicker(
                            localizationService.localizedString("departure_date"),
                            selection: $viewModel.query.departureDate,
                            displayedComponents: .date
                        )
                    }

                    Section(header: Text(localizationService.localizedString("passengers_section"))) {
                        Stepper(
                            value: $viewModel.query.passengers,
                            in: 1...9
                        ) {
                            Text(String(format: localizationService.localizedString("passengers_count"), viewModel.query.passengers))
                        }
                    }

                    Section {
                        Button {
                            viewModel.search()
                        } label: {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                }
                                Text(localizationService.localizedString("search_button"))
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(viewModel.isLoading)
                    }
                }

                if let message = viewModel.errorMessage, viewModel.flights.isEmpty {
                    Text(message)
                        .foregroundColor(.secondary)
                        .padding()
                }

                if !viewModel.flights.isEmpty {
                    List(viewModel.flights) { flight in
                        NavigationLink {
                            FlightDetailsView(viewModel: FlightDetailsViewModel(flight: flight))
                        } label: {
                            FlightRowView(flight: flight) {
                                viewModel.saveFlight(flight)
                            }
                        }
                    }
                    .listStyle(.plain)
                } else if !viewModel.isLoading {
                    Spacer()
                    Text(localizationService.localizedString("search_empty_state"))
                        .foregroundColor(.secondary)
                        .padding()
                    Spacer()
                }
            }
            .navigationTitle(localizationService.localizedString("search_title"))
        }
    }
}

struct FlightRowView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    let flight: Flight
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(flight.airline) \(flight.flightNumber)")
                    .font(.headline)
                Spacer()
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("\(flight.origin) → \(flight.destination)")
                        .font(.subheadline.bold())
                    Text(routeTimeRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(durationString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(priceString)
                        .font(.headline)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var routeTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: flight.departureDate)) - \(formatter.string(from: flight.arrivalDate))"
    }

    private var durationString: String {
        let hours = flight.durationMinutes / 60
        let minutes = flight.durationMinutes % 60
        if hours > 0 {
            return String(format: localizationService.localizedString("duration_hours_minutes"), hours, minutes)
        } else {
            return String(format: localizationService.localizedString("duration_minutes"), minutes)
        }
    }

    private var priceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = localizationService.currentLocale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numberString = formatter.string(from: NSNumber(value: flight.price)) ?? "\(flight.price)"
        return "$\(numberString)"
    }
}

#Preview {
    SearchView()
        .environmentObject(LocalizationService.shared)
        .environmentObject(ThemeService.shared)
        .environmentObject(SettingsViewModel())
}
