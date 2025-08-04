//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import SharingGRDB
import Common
import Db
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
        KarmicHealingView(store: delegate.store)
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
    $selectedReminderID
      .compactMap { $0 }
      .sink { [weak self] id in
        self?.store.send(.setSelectedReminderID(id))
      }
      .store(in: &cancellables)
  }

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    store.send(.onDidFinishLaunching)

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
      print("Notification permission granted: \(granted)")
    }
    return true
  }

  // MARK: - Notification Delegate
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let identifier = response.actionIdentifier
    
    switch identifier {
    case "OPEN_REMINDER_FORM", UNNotificationDefaultActionIdentifier:
      Task { @MainActor in
        // Витягуємо тип notification з userInfo
        let notificationTypeString = response.notification.request.content.userInfo["notificationType"] as? String
        let notificationType = NotificationType(rawValue: notificationTypeString ?? "") ?? .reminder
        
        switch notificationType {
        case .reminder:
          // Для reminder notification - відкриваємо RemindersDetailView
          if let reminderIDString = response.notification.request.content.userInfo["reminderID"] as? String,
             let reminderID = UUID(uuidString: reminderIDString) {
            print("AppDelegate: Opening RemindersDetailView for reminder: \(reminderID)")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: reminderID))))
          } else {
            print("AppDelegate: No reminderID found, opening RemindersDetailView without specific reminder")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: nil))))
          }
          
        case .balancingEnergy:
          // Для balancing energy notification - просто відкриваємо додаток
          print("AppDelegate: Balancing energy notification tapped - just opening app")
          // Не робимо нічого, просто відкриваємо додаток
          break
        }
      }
    default:
      break
    }

    completionHandler()
  }
}
