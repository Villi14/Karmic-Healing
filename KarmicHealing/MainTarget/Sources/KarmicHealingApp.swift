//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Common
import Db
import UserNotifications
import Combine

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
    // Запит дозволу на локальні сповіщення
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
    if let reminderIDString = response.notification.request.content.userInfo["reminderID"] as? String,
       let reminderID = UUID(uuidString: reminderIDString) {
      DispatchQueue.main.async {
        self.selectedReminderID = reminderID
      }
    }
    completionHandler()
  }
}
