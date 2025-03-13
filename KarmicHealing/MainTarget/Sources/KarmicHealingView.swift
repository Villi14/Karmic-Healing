//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Home
import Onboarding

struct KarmicHealingView: View {
  let store: StoreOf<KarmicHealing>

  var body: some View {
    let store = store.scope(state: \.destination, action: \.destination)

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
}
