//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Home
import Onboarding
import Common

struct KarmicHealingView: View {
  let store: StoreOf<KarmicHealing>
  @AppStorage(UserDefaultsClient.Keys.userTheme) private var userTheme: String = "system"

  var body: some View {
    let store = store.scope(state: \.destination, action: \.destination)
    Group {
      switch store.case {
      case let .onboarding(store):
        OnboardingView(store: store)
          .transition(.opacity)
          .onChange(of: store.isCompleted) { isCompleted, _ in
            if isCompleted {
              self.store.send(.destination(.onboarding(.completeOnboarding)))
            }
          }
      case let .home(store):
        HomeView(store: store)
          .transition(.opacity)
      }
    }
    .preferredColorScheme(colorSchemeFromTheme(userTheme))
  }
}

private func colorSchemeFromTheme(_ theme: String) -> ColorScheme? {
  switch theme {
  case "light": return .light
  case "dark": return .dark
  default: return nil // system
  }
}
