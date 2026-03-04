import Foundation
import UIKit
import Combine
import UserNotifications

final class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()

    @Published var isEnabled: Bool = false
    @Published private(set) var isAuthorized: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        
        refreshAuthorizationStatus()
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.refreshAuthorizationStatus()
            }
            .store(in: &cancellables)
    }

    func requestAuthorization() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { [weak self] granted, error in
            
            if let error = error {
                print("❗ Notification permission error:", error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }
    
    func refreshAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized ||
                settings.authorizationStatus == .provisional
            }
        }
    }
    
    /// Запрос разрешения на уведомления
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if let error = error {
                print("❗ Notification permission error:", error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// Проверка текущего статуса разрешения
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func loadFlightsAndStart() {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            do {
                let flights = try DatabaseService.shared.fetchSavedFlights()
                DispatchQueue.main.async {
                    self.startRepeatingNotification(from: flights)
                }
            } catch {
                print("Failed to load flights: \(error)")
            }
        }
    }
    
    func startRepeatingNotification(from flights: [SavedFlightModel]) {
        guard let flight = flights.randomElement() else { return }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        let title = "\(flight.airline) \(flight.flightNumber)"
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        let dateStr = formatter.string(from: flight.departureDate)
        let body = "\(flight.origin) → \(flight.destination) on \(dateStr) - $\(String(format: "%.2f", flight.price))"
        let timeInterval = TimeInterval(60)
        
        startRepeatingNotification(id: flight.id.uuidString, title: title, body: body, timeInterval: timeInterval)
    }
    
    /// Запуск повторяющегося уведомления
    func startRepeatingNotification(
        id: String,
        title: String,
        body: String,
        timeInterval: TimeInterval,
        repeats: Bool = true
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: repeats
        )
        
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❗ Error scheduling notification:", error.localizedDescription)
            } else {
                print("✅ Notification scheduled with id:", id)
            }
        }
    }
    
    /// Остановить конкретное уведомление
    func stopNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [id])
        
        print("🛑 Notification stopped:", id)
    }
    
    /// Остановить все уведомления
    func stopAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        print("🛑 All notifications stopped")
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    
    /// Показывать уведомление даже если приложение открыто
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
