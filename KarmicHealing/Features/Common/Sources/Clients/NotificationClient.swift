//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import UserNotifications
import XCTestDynamicOverlay
import AppIntents

extension DependencyValues {
  public var notification: NotificationClient {
    get { self[NotificationClient.self] }
    set { self[NotificationClient.self] = newValue }
  }
}

public struct NotificationClient {
  public var requestAuthorization: @Sendable () async -> Bool
  public var scheduleLocalNotification: @Sendable (String, String, TimeInterval) -> Void
  public var scheduleReminderNotification: @Sendable (String, String, TimeInterval, UUID?) -> Void
  public var scheduleReminderNotificationWithIntent: @Sendable (String, String, TimeInterval, UUID?) -> Void
  public var cancelAllNotifications: @Sendable () -> Void
  
  public init(
    requestAuthorization: @escaping @Sendable () async -> Bool,
    scheduleLocalNotification: @escaping @Sendable (String, String, TimeInterval) -> Void,
    scheduleReminderNotification: @escaping @Sendable (String, String, TimeInterval, UUID?) -> Void,
    scheduleReminderNotificationWithIntent: @escaping @Sendable (String, String, TimeInterval, UUID?) -> Void,
    cancelAllNotifications: @escaping @Sendable () -> Void
  ) {
    self.requestAuthorization = requestAuthorization
    self.scheduleLocalNotification = scheduleLocalNotification
    self.scheduleReminderNotification = scheduleReminderNotification
    self.scheduleReminderNotificationWithIntent = scheduleReminderNotificationWithIntent
    self.cancelAllNotifications = cancelAllNotifications
  }
}

extension NotificationClient: DependencyKey {
  public static let liveValue: Self = {
    let center = UNUserNotificationCenter.current()
    
    return Self(
      requestAuthorization: {
        do {
          return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
          print("Failed to request notification authorization: \(error)")
          return false
        }
      },
      scheduleLocalNotification: { title, body, timeInterval in
        // Валідуємо timeInterval - має бути >= 1 секунда
        let validTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: validTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "auto-scroll", content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("Failed to schedule notification: \(error)")
          }
        }
      },
      scheduleReminderNotification: { title, body, timeInterval, reminderID in
        // Валідуємо timeInterval - має бути >= 1 секунда
        let validTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Встановлюємо category для обробки в AppDelegate
        content.categoryIdentifier = "REMINDER_FORM"
        
        // Додаємо reminderID в userInfo для навігації
        let reminderIDString = reminderID?.uuidString ?? UUID().uuidString
        content.userInfo = ["reminderID": reminderIDString]
        
        // Встановлюємо interruptionLevel для iOS 18+
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: validTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder-\(reminderIDString)", content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("NotificationClient: Failed to schedule reminder notification: \(error)")
          }
        }
      },
      scheduleReminderNotificationWithIntent: { title, body, timeInterval, reminderID in
        // Валідуємо timeInterval - має бути >= 1 секунда
        let validTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "REMINDER_FORM"
        
        // Додаємо reminderID в userInfo для навігації
        let reminderIDString = reminderID?.uuidString ?? UUID().uuidString
        content.userInfo = ["reminderID": reminderIDString]
        
        // Встановлюємо interruptionLevel для iOS 18+
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: validTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "reminder-intent-\(reminderIDString)", content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("NotificationClient: Failed to schedule reminder notification with intent: \(error)")
          }
        }
      },
      cancelAllNotifications: {
        center.removeAllPendingNotificationRequests()
      }
    )
  }()
  
  public static let testValue: Self = Self(
    requestAuthorization: { true },
    scheduleLocalNotification: { _, _, _ in },
    scheduleReminderNotification: { _, _, _, _ in },
    scheduleReminderNotificationWithIntent: { _, _, _, _ in },
    cancelAllNotifications: { }
  )
}
