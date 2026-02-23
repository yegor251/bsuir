import Foundation
import Combine
import UserNotifications

final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.notificationsEnabledKey)
        }
    }

    private static let notificationsEnabledKey = "notificationsEnabled"
    private var timer: Timer?
    private var currentFlights: [SavedFlightModel] = []

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.notificationsEnabledKey)
    }

    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func loadFlightsAndStart() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                let flights = try DatabaseService.shared.fetchSavedFlights()
                DispatchQueue.main.async {
                    self.startPeriodicNotifications(flights: flights)
                }
            } catch {
                print("Failed to load flights: \(error)")
            }
        }
    }

    func scheduleRandomFlightNotification(from flights: [SavedFlightModel]) {
        guard let flight = flights.randomElement() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(flight.airline) \(flight.flightNumber)"
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let dateStr = formatter.string(from: flight.departureDate)
        content.body = "\(flight.origin) → \(flight.destination) on \(dateStr) - $\(String(format: "%.2f", flight.price))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Ошибка отправки уведомления: \(error.localizedDescription)")
                } else {
                    print("Уведомление успешно")
                }
            }
    }

    func startPeriodicNotifications(flights: [SavedFlightModel]) {
        stopNotifications()
        guard !flights.isEmpty else { return }

        currentFlights = flights
        scheduleRandomFlightNotification(from: currentFlights)

        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            guard let self = self, self.isEnabled else { return }
            if self.currentFlights.isEmpty {
                self.stopNotifications()
                return
            }
            self.scheduleRandomFlightNotification(from: self.currentFlights)
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopNotifications() {
        timer?.invalidate()
        timer = nil
        currentFlights = []
    }
}
