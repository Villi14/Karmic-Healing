//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import OSLog
import UserNotifications
import XCTestDynamicOverlay
import AppIntents

public enum NotificationType: String, CaseIterable {
  case reminder = "REMINDER"
  /// No longer scheduled — kept so a build that did schedule them can still be swept clean.
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
  public var scheduleReminderNotification: @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void
  public var scheduleReminderNotificationWithIntent: @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void
  /// Drops every balancing-energy notification an older build left pending. Reminders are untouched.
  public var purgeSessionNotifications: @Sendable () -> Void

  public init(
    requestAuthorization: @escaping @Sendable () async -> Bool,
    scheduleReminderNotification: @escaping @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void,
    scheduleReminderNotificationWithIntent: @escaping @Sendable (String, String, TimeInterval, UUID?, UUID?, NotificationType) -> Void,
    purgeSessionNotifications: @escaping @Sendable () -> Void
  ) {
    self.requestAuthorization = requestAuthorization
    self.scheduleReminderNotification = scheduleReminderNotification
    self.scheduleReminderNotificationWithIntent = scheduleReminderNotificationWithIntent
    self.purgeSessionNotifications = purgeSessionNotifications
  }
}

/// Removes every pending balancing-energy request, matching on the category so a reminder is never
/// caught by mistake.
///
/// A session no longer schedules anything, but a device updated from a build that did still carries
/// the tail, and those notifications would keep firing long after the app was closed.
func purgePendingSessionNotifications(in center: UNUserNotificationCenter) {
  center.getPendingNotificationRequests { requests in
    let identifiers = requests
      .filter { $0.content.categoryIdentifier == NotificationType.balancingEnergy.rawValue }
      .map(\.identifier)

    guard !identifiers.isEmpty else { return }
    center.removePendingNotificationRequests(withIdentifiers: identifiers)
    Log.notifications.notice(
      "Purged \(identifiers.count, privacy: .public) leftover balancing energy notifications"
    )
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
          Log.notifications.error("Failed to request authorization: \(error.localizedDescription, privacy: .public)")
          return false
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
            Log.notifications.error("Failed to schedule reminder notification: \(error.localizedDescription, privacy: .public)")
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
            Log.notifications.error("Failed to schedule reminder notification with intent: \(error.localizedDescription, privacy: .public)")
          }
        }
      },
      purgeSessionNotifications: {
        purgePendingSessionNotifications(in: center)
      }
    )
  }()

  public static let testValue: Self = Self(
    requestAuthorization: { true },
    scheduleReminderNotification: { _, _, _, _, _, _ in },
    scheduleReminderNotificationWithIntent: { _, _, _, _, _, _ in },
    purgeSessionNotifications: { }
  )
}
