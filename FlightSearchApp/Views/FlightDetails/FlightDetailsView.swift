import SwiftUI
import UIKit

struct FlightDetailsView: View {
    @EnvironmentObject private var localizationService: LocalizationService
    @StateObject private var viewModel: FlightDetailsViewModel

    /// Путь к фото рейса (для сохранённых). Если передан, показывается секция «Фото» и кнопка «Сделать фото».
    var photoPath: String? = nil
    /// Вызывается после съёмки фото. Возвращает путь к сохранённому файлу или nil.
    var onAddPhoto: ((UIImage) -> String?)? = nil

    init(flight: Flight, isSaved: Bool = false, notes: String = "", title: String = "", notes2: String = "", photoPath: String? = nil, onAddPhoto: ((UIImage) -> String?)? = nil) {
        _viewModel = StateObject(wrappedValue: FlightDetailsViewModel(
            flight: flight,
            isSaved: isSaved,
            notes: notes,
            title: title,
            notes2: notes2
        ))
        self.photoPath = photoPath
        self.onAddPhoto = onAddPhoto
    }

    @State private var sharing: Bool = false
    @State private var weatherViewId = UUID()
    @State private var displayedPhotoPath: String? = nil
    @State private var showCamera = false

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
                if viewModel.isSaved, onAddPhoto != nil {
                    photoSection
                }
                Spacer(minLength: 16)
            }
            .padding()
        }
        .onAppear {
            print("FlightDetailsView onAppear, flight destination=\(viewModel.flight.destination)")
            displayedPhotoPath = photoPath
            Task {
                await viewModel.loadWeather()
            }
        }
        .onChange(of: photoPath) { _, new in
            displayedPhotoPath = new
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
                HStack(spacing: 16) {
                    Button {
                        shareTitleAndNotes()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button {
                        viewModel.toggleSaved()
                    } label: {
                        Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                    }
                }
            }
        }
        .sheet(isPresented: $sharing) {
            ActivityView(activityItems: [shareTitleAndNotesText])
        }
        .sheet(isPresented: $showCamera) {
            CameraImagePicker(image: .constant(nil)) { image in
                if let image = image, let add = onAddPhoto, let path = add(image) {
                    displayedPhotoPath = path
                }
            }
        }
    }

    /// Текст для шаринга: title + пробел + notes.
    private var shareTitleAndNotesText: String {
        [viewModel.title, viewModel.notes]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
    }

    private func shareTitleAndNotes() {
        sharing = true
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localizationService.localizedString("photo_title"))
                .font(.headline)
            let pathToShow = displayedPhotoPath ?? photoPath
            if let path = pathToShow, FileManager.default.fileExists(atPath: path),
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button {
                showCamera = true
            } label: {
                Label(localizationService.localizedString("photo_add_button"), systemImage: "camera.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
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

/// Открывает камеру устройства; по завершении вызывает `onFinish` с полученным изображением или nil при отмене.
struct CameraImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onFinish: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onFinish: (UIImage?) -> Void

        init(onFinish: @escaping (UIImage?) -> Void) {
            self.onFinish = onFinish
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let img = info[.originalImage] as? UIImage
            picker.dismiss(animated: true) { [onFinish] in
                onFinish(img)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { [onFinish] in
                onFinish(nil)
            }
        }
    }
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
