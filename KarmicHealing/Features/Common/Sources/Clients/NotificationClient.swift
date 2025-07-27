import Foundation
import UserNotifications

public struct NotificationClient {
  public static let shared = NotificationClient()
  private let center = UNUserNotificationCenter.current()

  private init() {}

  public func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
    center.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: completion)
  }

  public func scheduleNotification(id: String, title: String, body: String, date: Date, reminderID: UUID, repeats: Bool = false, soundName: String? = nil) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.userInfo = ["reminderID": reminderID.uuidString]
    if let soundName = soundName {
      content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
    } else {
      content.sound = .default
    }
    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: repeats)
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    center.add(request) { error in
      if let error = error {
        print("Failed to schedule notification: \(error)")
      }
    }
  }

  public func removeNotification(id: String) {
    center.removePendingNotificationRequests(withIdentifiers: [id])
  }

  public func removeAllNotifications() {
    center.removeAllPendingNotificationRequests()
  }

  public func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
    center.getPendingNotificationRequests(completionHandler: completion)
  }
}
