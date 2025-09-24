//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import XCTestDynamicOverlay
@preconcurrency import UserNotifications

public enum WatchNotificationType: String, CaseIterable, Sendable {
  case balancingEnergy = "BALANCING_ENERGY"
}

extension DependencyValues {
  public var watchNotification: WatchNotificationClient {
    get { self[WatchNotificationClient.self] }
    set { self[WatchNotificationClient.self] = newValue }
  }
}

public struct WatchNotificationClient {
  public var requestAuthorization: @Sendable () async -> Bool
  public var scheduleLocalNotification: @Sendable (String, String, TimeInterval, WatchNotificationType, String, Int) -> Void
  public var cancelBalancingEnergyNotifications: @Sendable () -> Void
  
  public init(
    requestAuthorization: @escaping @Sendable () async -> Bool,
    scheduleLocalNotification: @escaping @Sendable (String, String, TimeInterval, WatchNotificationType, String, Int) -> Void,
    cancelBalancingEnergyNotifications: @escaping @Sendable () -> Void
  ) {
    self.requestAuthorization = requestAuthorization
    self.scheduleLocalNotification = scheduleLocalNotification
    self.cancelBalancingEnergyNotifications = cancelBalancingEnergyNotifications
  }
}

extension WatchNotificationClient: DependencyKey {
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
      scheduleLocalNotification: { title, body, timeInterval, type, processTitle, currentStep in
        // Validate timeInterval - must be >= 1 second
        let validTimeInterval = max(1.0, timeInterval)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.rawValue
        
        // Add notification type, process title and current step to userInfo
        content.userInfo = [
          "notificationType": type.rawValue,
          "processTitle": processTitle,
          "currentStep": currentStep
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: validTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: "\(type.rawValue.lowercased())-\(UUID().uuidString)", content: content, trigger: trigger)
        
        center.add(request) { error in
          if let error = error {
            print("Failed to schedule notification: \(error)")
          } else {
            print("WatchNotificationClient: Successfully scheduled \(type.rawValue) notification with identifier: \(request.identifier)")
          }
        }
      },
      cancelBalancingEnergyNotifications: {
        center.getPendingNotificationRequests { requests in
          let balancingEnergyIdentifiers = requests.compactMap { request in
            let userInfo = request.content.userInfo
            if let notificationType = userInfo["notificationType"] as? String,
               notificationType == WatchNotificationType.balancingEnergy.rawValue {
              return request.identifier
            }
            return nil
          }
          
          if !balancingEnergyIdentifiers.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: balancingEnergyIdentifiers)
            print("WatchNotificationClient: Cancelled \(balancingEnergyIdentifiers.count) balancing energy notifications")
            print("WatchNotificationClient: Cancelled identifiers: \(balancingEnergyIdentifiers)")
          } else {
            print("WatchNotificationClient: No balancing energy notifications found to cancel")
          }
        }
      }
    )
  }()
  
  public static let testValue: Self = Self(
    requestAuthorization: { true },
    scheduleLocalNotification: { _, _, _, _, _, _ in },
    cancelBalancingEnergyNotifications: { }
  )
}

