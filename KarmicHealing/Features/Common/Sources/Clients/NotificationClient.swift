//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import UserNotifications
import XCTestDynamicOverlay
import AppIntents

public enum NotificationType: String, CaseIterable {
  case reminder = "REMINDER"
  case balancingEnergy = "BALANCING_ENERGY"
}

extension DependencyValues {
  public var notification: NotificationClient {
    get { self[NotificationClient.self] }
    set { self[NotificationClient.self] = newValue }
  }
}

public struct NotificationClient {
  public var requestAuthorization: @Sendable () async -> Bool
  public var scheduleLocalNotification: @Sendable (String, String, TimeInterval, NotificationType) -> Void
  public var scheduleReminderNotification: @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void
  public var scheduleReminderNotificationWithIntent: @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void
  public var cancelAllNotifications: @Sendable () -> Void
  
  public init(
    requestAuthorization: @escaping @Sendable () async -> Bool,
    scheduleLocalNotification: @escaping @Sendable (String, String, TimeInterval, NotificationType) -> Void,
    scheduleReminderNotification: @escaping @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void,
    scheduleReminderNotificationWithIntent: @escaping @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void,
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
      scheduleLocalNotification: { title, body, timeInterval, type in
        // Validate timeInterval - must be >= 1 second
        let validTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.rawValue
        
        // Add notification type to userInfo
        content.userInfo = ["notificationType": type.rawValue]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: validTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "\(type.rawValue.lowercased())-\(UUID().uuidString)", content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("Failed to schedule notification: \(error)")
          }
        }
      },
      scheduleReminderNotification: { title, body, timeInterval, reminderID, reminderListID, type in
        // Validate timeInterval - must be >= 1 second
        let validTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Set category for processing in AppDelegate
        content.categoryIdentifier = type.rawValue
        
        // Add reminderID, reminderListID and notification type to userInfo for navigation
        let reminderIDString = reminderID?.uuidString ?? UUID().uuidString
        let reminderListIDString = reminderListID?.uuidString ?? ""
        content.userInfo = [
          "reminderID": reminderIDString,
          "reminderListID": reminderListIDString,
          "notificationType": type.rawValue
        ]
        
        // Set interruptionLevel for iOS 18+
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: validTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "\(type.rawValue.lowercased())-\(reminderIDString)", content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("NotificationClient: Failed to schedule reminder notification: \(error)")
          }
        }
      },
      scheduleReminderNotificationWithIntent: { title, body, timeInterval, reminderID, reminderListID, type in
        // Validate timeInterval - must be >= 1 second
        let validTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.rawValue
        
        // Add reminderID, reminderListID and notification type to userInfo for navigation
        let reminderIDString = reminderID?.uuidString ?? UUID().uuidString
        let reminderListIDString = reminderListID?.uuidString ?? ""
        content.userInfo = [
          "reminderID": reminderIDString,
          "reminderListID": reminderListIDString,
          "notificationType": type.rawValue
        ]
        
        // Set interruptionLevel for iOS 18+
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: validTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "\(type.rawValue.lowercased())-intent-\(reminderIDString)", content: content, trigger: trigger)
        
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
    scheduleLocalNotification: { _, _, _, _ in },
    scheduleReminderNotification: { _, _, _, _, _, _ in },
    scheduleReminderNotificationWithIntent: { _, _, _, _, _, _ in },
    cancelAllNotifications: { }
  )
}
