//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Reminders

@main
struct KarmicHealingApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

  var body: some Scene {
    WindowGroup {
      KarmicHealingView(store: delegate.store)
    }
  }
}

private class AppDelegate: UIResponder, UIApplicationDelegate {
  let store: StoreOf<KarmicHealing>
  
  override init() {
    store = .init(
      initialState: .init(),
      reducer: {
        KarmicHealing()
          .dependency(\.context, ComposableArchitecture._XCTIsTesting ? .preview : .live)
      }
    )
    super.init()
  }
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    store.send(.onDidFinishLaunching)
    return true
  }
}
