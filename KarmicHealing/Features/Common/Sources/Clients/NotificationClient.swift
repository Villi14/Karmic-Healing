//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import UserNotifications
import XCTestDynamicOverlay

extension DependencyValues {
  public var notifications: NotificationClient {
    get { self[NotificationClient.self] }
    set { self[NotificationClient.self] = newValue }
  }
}

public struct NotificationClient {
  public var requestAuthorization: @Sendable () async -> Bool
  public var scheduleNotification: @Sendable (String, String, String, Date, UUID, Bool, String?) async -> Void
  public var removeNotification: @Sendable (String) async -> Void
  public var removeAllNotifications: @Sendable () async -> Void
  public var getPendingNotifications: @Sendable () async -> [UNNotificationRequest]

  public init(
    requestAuthorization: @Sendable @escaping () async -> Bool,
    scheduleNotification: @Sendable @escaping (String, String, String, Date, UUID, Bool, String?) async -> Void,
    removeNotification: @Sendable @escaping (String) async -> Void,
    removeAllNotifications: @Sendable @escaping () async -> Void,
    getPendingNotifications: @Sendable @escaping () async -> [UNNotificationRequest]
  ) {
    self.requestAuthorization = requestAuthorization
    self.scheduleNotification = scheduleNotification
    self.removeNotification = removeNotification
    self.removeAllNotifications = removeAllNotifications
    self.getPendingNotifications = getPendingNotifications
  }
}

extension NotificationClient: DependencyKey {
  public static let liveValue: Self = {
    let center = UNUserNotificationCenter.current()
    
    return Self(
      requestAuthorization: {
        return await withCheckedContinuation { continuation in
          center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            continuation.resume(returning: granted)
          }
        }
      },
      scheduleNotification: { id, title, body, date, reminderID, repeats, soundName in
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
        
        do {
          try await center.add(request)
        } catch {
          print("Failed to schedule notification: \(error)")
        }
      },
      removeNotification: { id in
        center.removePendingNotificationRequests(withIdentifiers: [id])
      },
      removeAllNotifications: {
        center.removeAllPendingNotificationRequests()
      },
      getPendingNotifications: {
        return await withCheckedContinuation { continuation in
          center.getPendingNotificationRequests { requests in
            continuation.resume(returning: requests)
          }
        }
      }
    )
  }()
  
  public static let testValue: Self = {
    return Self(
      requestAuthorization: { true },
      scheduleNotification: { _, _, _, _, _, _, _ in },
      removeNotification: { _ in },
      removeAllNotifications: { },
      getPendingNotifications: { [] }
    )
  }()
}

// MARK: - Convenience methods
extension NotificationClient {
  public func scheduleNotification(
    id: String,
    title: String,
    body: String,
    date: Date,
    reminderID: UUID,
    repeats: Bool = false,
    soundName: String? = nil
  ) async {
    await scheduleNotification(id, title, body, date, reminderID, repeats, soundName)
  }
  
  public func scheduleNotification(
    id: String,
    title: String,
    body: String,
    date: Date,
    repeats: Bool = false,
    soundName: String? = nil
  ) async {
    await scheduleNotification(id, title, body, date, UUID(), repeats, soundName)
  }
}
