import SwiftUI

struct FlightDetailsView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    @StateObject private var viewModel: FlightDetailsViewModel
        
    init(flight: Flight, isSaved: Bool = false, notes: String = "", title: String = "", notes2: String = "") {
        _viewModel = StateObject(wrappedValue: FlightDetailsViewModel(
            flight: flight,
            isSaved: isSaved,
            notes: notes,
            title: title,
            notes2: notes2
        ))
    }

    @State private var sharing: Bool = false
    @State private var weatherViewId = UUID()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                titleSection
                routeVisualization
                layoverSection
                priceSection
                weatherSection
                    .id(weatherViewId)
                notesSection
                notes2Section
                Spacer(minLength: 16)
            }
            .padding()
        }
        .onAppear {
            print("FlightDetailsView onAppear, flight destination=\(viewModel.flight.destination)")
            Task {
                await viewModel.loadWeather()
            }
        }
        .onChange(of: viewModel.temperature) { oldValue, newValue in
            print("FlightDetailsView weatherSection reload, old=\(String(describing: oldValue)), new=\(String(describing: newValue))")
            weatherViewId = UUID()
        }
        .onDisappear {
            viewModel.saveUpdates()
        }
        .navigationTitle(localizationService.localizedString("details_title"))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleSaved()
                } label: {
                    Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                }
            }
        }
        .sheet(isPresented: $sharing) {
            let shareText = "\(viewModel.flight.airline) \(viewModel.flight.flightNumber) \(viewModel.flight.origin) → \(viewModel.flight.destination)"
            ActivityView(activityItems: [shareText])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(viewModel.flight.airline) \(viewModel.flight.flightNumber)")
                .font(.title2.bold())
            Text("\(viewModel.flight.origin) → \(viewModel.flight.destination)")
                .font(.headline)
            Text(timeRange)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var routeVisualization: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(viewModel.flight.origin)
                    .font(.headline)
                Text(departureTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack {
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(.blue)
                    .overlay(
                        Image(systemName: "airplane")
                            .foregroundColor(.blue)
                    )
                Text(durationString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(viewModel.flight.destination)
                    .font(.headline)
                Text(arrivalTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private var layoverSection: some View {
        Group {
            if !viewModel.flight.layovers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localizationService.localizedString("layovers_title"))
                        .font(.headline)
                    ForEach(viewModel.flight.layovers, id: \.self) { code in
                        Text(code)
                            .font(.subheadline)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizationService.localizedString("layovers_title"))
                        .font(.headline)
                    Text(localizationService.localizedString("layovers_none"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "thermometer.medium")
                Text(localizationService.localizedString("weather_title"))
                    .font(.headline)
            }

            if let temperature = viewModel.temperature {
                Text(String(format: "%.0f°C", temperature))
                    .font(.title3.bold())
            } else {
                switch viewModel.weatherState {
                case .loading:
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(localizationService.localizedString("weather_loading"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                case .offline:
                    Text(localizationService.localizedString("weather_offline_unavailable"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                case .loaded, .error:
                    Text(localizationService.localizedString("weather_error"))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }

    private var priceSection: some View {
        let price = viewModel.flight.price
        return VStack(alignment: .leading, spacing: 8) {
            Text(localizationService.localizedString("price_title"))
                .font(.headline)
            HStack {
                Text(localizationService.localizedString("price_total"))
                    .fontWeight(.semibold)
                Spacer()
                Text(priceFormatted(price))
                    .fontWeight(.semibold)
            }
        }
    }

    private func priceFormatted(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = localizationService.currentLocale
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let numberString = formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "$\(numberString)"
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationService.localizedString("title_label"))
                .font(.headline)
            TextField(localizationService.localizedString("title_placeholder"), text: $viewModel.title)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationService.localizedString("notes_title"))
                .font(.headline)
            TextEditor(text: $viewModel.notes)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
        }
    }

    private var notes2Section: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationService.localizedString("notes2_title"))
                .font(.headline)
            TextEditor(text: $viewModel.notes2)
                .frame(minHeight: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
        }
    }

    private var timeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: viewModel.flight.departureDate)) - \(formatter.string(from: viewModel.flight.arrivalDate))"
    }

    private var departureTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: viewModel.flight.departureDate)
    }

    private var arrivalTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: viewModel.flight.arrivalDate)
    }

    private var durationString: String {
        let hours = viewModel.flight.durationMinutes / 60
        let minutes = viewModel.flight.durationMinutes % 60
        if hours > 0 {
            return String(format: localizationService.localizedString("duration_hours_minutes"), hours, minutes)
        } else {
            return String(format: localizationService.localizedString("duration_minutes"), minutes)
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    FlightDetailsView(
        flight: Flight(
            airline: "Swift Air",
            flightNumber: "SA123",
            origin: "MOW",
            destination: "NYC",
            departureDate: Date(),
            arrivalDate: Date().addingTimeInterval(3 * 3600),
            durationMinutes: 180,
            price: 15000
        )
    )
    .environmentObject(LocalizationService.shared)
}
