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
    
    // Watch connectivity disabled - watch is now independent
    print("AppDelegate: Watch connectivity disabled - watch is independent")
    
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

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
      if let error = error {
        print("Notification permission error: \(error)")
      }
      print("Notification permission granted: \(granted)")
    }
    
    // Watch connectivity disabled - watch is now independent
    print("AppDelegate: Watch connectivity disabled - watch is independent")
    
    return true
  }
  
  func applicationWillTerminate(_ application: UIApplication) {
    // Cancel only balancing energy notifications when app is about to terminate
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      let balancingEnergyIdentifiers = requests.compactMap { request in
        let userInfo = request.content.userInfo
        
        if let notificationType = userInfo["notificationType"] as? String, notificationType == "BALANCING_ENERGY" {
          return request.identifier
        }
        return nil
      }
      
      if !balancingEnergyIdentifiers.isEmpty {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: balancingEnergyIdentifiers)
        print("AppDelegate: Cancelled \(balancingEnergyIdentifiers.count) balancing energy notifications on app termination")
      }
    }
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    print("AppDelegate: App entering foreground - watch is independent")
  }
  
  func applicationDidBecomeActive(_ application: UIApplication) {
    print("AppDelegate: App became active - watch is independent")
  }
  
  func applicationDidEnterBackground(_ application: UIApplication) {
    // Don't cancel balancing energy notifications when app goes to background
    // They should continue working if user is still in meditation process
    print("AppDelegate: App went to background - keeping balancing energy notifications active")
  }

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
            print("AppDelegate: Opening RemindersDetailView for reminder: \(reminderID) in list: \(reminderListID)")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: reminderID, reminderListID: reminderListID))))
          } else if let reminderIDString = response.notification.request.content.userInfo["reminderID"] as? String,
                    let reminderID = UUID(uuidString: reminderIDString) {
            print("AppDelegate: Opening RemindersDetailView for reminder: \(reminderID) without list")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: reminderID))))
          } else {
            print("AppDelegate: No reminderID found, opening RemindersDetailView without specific reminder")
            self.store.send(.destination(.home(.resetNavigationAndOpenReminder(reminderID: nil))))
          }
          
        case .balancingEnergy:
          // For balancing energy notification - just open the app
          print("AppDelegate: Balancing energy notification tapped - just opening app")
          // Do nothing, just open the app
          break
        }
      }
    default:
      break
    }

    completionHandler()
  }
  
  // MARK: - Language Change Handler
  @objc private func languageDidChange() {
    print("AppDelegate: Language changed - watch is independent, no sync needed")
  }
}