//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import UserNotifications
import XCTestDynamicOverlay

extension DependencyValues {
  public var notification: NotificationClient {
    get { self[NotificationClient.self] }
    set { self[NotificationClient.self] = newValue }
  }
}

public struct NotificationClient {
  public var requestAuthorization: @Sendable () async -> Bool
  public var scheduleLocalNotification: @Sendable (String, String, TimeInterval) -> Void
  public var cancelAllNotifications: @Sendable () -> Void
  
  public init(
    requestAuthorization: @escaping @Sendable () async -> Bool,
    scheduleLocalNotification: @escaping @Sendable (String, String, TimeInterval) -> Void,
    cancelAllNotifications: @escaping @Sendable () -> Void
  ) {
    self.requestAuthorization = requestAuthorization
    self.scheduleLocalNotification = scheduleLocalNotification
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
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "auto-scroll", content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("Failed to schedule notification: \(error)")
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
    cancelAllNotifications: { }
  )
}
