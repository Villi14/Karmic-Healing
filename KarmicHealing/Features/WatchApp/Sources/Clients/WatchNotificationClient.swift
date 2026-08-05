//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import OSLog
import XCTestDynamicOverlay
@preconcurrency import UserNotifications

public enum WatchNotificationType: String, CaseIterable, Sendable {
  /// No longer scheduled — kept so a build that did schedule them can still be swept clean.
  case balancingEnergy = "BALANCING_ENERGY"
}

extension DependencyValues {
  public var watchNotification: WatchNotificationClient {
    get { self[WatchNotificationClient.self] }
    set { self[WatchNotificationClient.self] = newValue }
  }
}

/// The watch schedules no notifications: a session runs only while the app is on the wrist and in
/// front of the user. All that is left is clearing what an older build queued up.
public struct WatchNotificationClient {
  public var purgeSessionNotifications: @Sendable () -> Void

  public init(purgeSessionNotifications: @escaping @Sendable () -> Void) {
    self.purgeSessionNotifications = purgeSessionNotifications
  }
}

extension WatchNotificationClient: DependencyKey {
  public static let liveValue: Self = {
    let center = UNUserNotificationCenter.current()

    return Self(
      purgeSessionNotifications: {
        center.getPendingNotificationRequests { requests in
          let identifiers = requests
            .filter { $0.content.categoryIdentifier == WatchNotificationType.balancingEnergy.rawValue }
            .map(\.identifier)

          guard !identifiers.isEmpty else { return }
          center.removePendingNotificationRequests(withIdentifiers: identifiers)
          Log.notifications.notice(
            "Purged \(identifiers.count, privacy: .public) leftover balancing energy notifications"
          )
        }
      }
    )
  }()

  public static let testValue: Self = Self(purgeSessionNotifications: { })
}
