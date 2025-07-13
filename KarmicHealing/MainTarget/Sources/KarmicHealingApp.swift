//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Common

@main
struct KarmicHealingApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
  @Dependency(\.context) var context

  var body: some Scene {
    WindowGroup {
      if context == .live {
        KarmicHealingView(store: delegate.store)
      }
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
