//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import SQLiteData
import BalancingEnergy
import Common
import Db
import OSLog
import UserNotifications
import Combine

// MARK: - Notification Names

extension Notification.Name {
  static let openReminderForm = Notification.Name("openReminderForm")
}

@main
struct KarmicHealingApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
  @Dependency(\.context) var context

  init() {
    if context == .live {
      try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      if context == .live {
        AppLockView {
          KarmicHealingView(store: delegate.store)
        }
      }
    }
  }
}

private class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  let store: StoreOf<KarmicHealing>
  @Published var selectedReminderID: UUID?
  @Published var shouldOpenReminderForm = false
  private var cancellables = Set<AnyCancellable>()

  override init() {
    store = .init(
      initialState: .init(),
      reducer: {
        KarmicHealing()
          .dependency(\.context, ComposableArchitecture._XCTIsTesting ? .preview : .live)
      }
    )
    super.init()
    UNUserNotificationCenter.current().delegate = self

    // Listen for language changes
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(languageDidChange),
      name: NSLocale.currentLocaleDidChangeNotification,
      object: nil
    )
    
    $selectedReminderID
      .compactMap { $0 }
      .sink { [weak self] id in
        self?.store.send(.setSelectedReminderID(id))
      }
      .store(in: &cancellables)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    store.send(.onDidFinishLaunching)

    // Brightness is a system setting: if a session was killed mid-rest, the user would otherwise
    // be left with a black phone and no idea why.
    @Dependency(\.screen) var screen
    screen.restoreAfterUncleanExit()

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error {
        Log.notifications.error("Permission request failed: \(error.localizedDescription, privacy: .public)")
      }
      Log.notifications.notice("Notification permission granted: \(granted, privacy: .public)")
    }

    return true
  }
  
  // A balancing energy session schedules no notifications at all: it runs only while the user is
  // in the app, so nothing can arrive once the app is closed. Reminders are unaffected — a
  // reminder is meant to fire with the app shut.

  // MARK: - Notification Delegate
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let identifier = response.actionIdentifier
    
    switch identifier {
    case "OPEN_REMINDER_FORM", UNNotificationDefaultActionIdentifier:
      Task { @MainActor in
        // Extract notification type from userInfo
        let notificationTypeString = response.notification.request.content.userInfo["notificationType"] as? String
        let notificationType = NotificationType(rawValue: notificationTypeString ?? "") ?? .reminder

        switch notificationType {
        case .reminder:
          // For reminder notification - open RemindersDetailView
          if let reminderIDString = response.notification.request.content.userInfo["reminderID"] as? String,
             let reminderID = UUID(uuidString: reminderIDString),
             let reminderListIDString = response.notification.request.content.userInfo["reminderListID"] as? String,
             let reminderListID = UUID(uuidString: reminderListIDString) {
            Log.notifications.notice("Opening reminder \(reminderID, privacy: .public) in list \(reminderListID, privacy: .public)")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: reminderID, reminderListID: reminderListID))))
          } else if let reminderIDString = response.notification.request.content.userInfo["reminderID"] as? String,
                    let reminderID = UUID(uuidString: reminderIDString) {
            Log.notifications.notice("Opening reminder \(reminderID, privacy: .public) without a list")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: reminderID))))
          } else {
            Log.notifications.notice("Reminder notification carried no reminderID, opening the list")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: nil))))
          }

        case .balancingEnergy:
          // Only a leftover from an older build can land here, and it has no session to reopen.
          Log.notifications.notice("Ignoring a stale balancing energy notification")
        }
      }
    default:
      break
    }

    completionHandler()
  }
  
  // MARK: - Language Change Handler
  // The watch app is independent, so a locale change needs no sync — the observer is kept
  // as the hook for anything the app itself needs to refresh.
  @objc private func languageDidChange() {}
}
