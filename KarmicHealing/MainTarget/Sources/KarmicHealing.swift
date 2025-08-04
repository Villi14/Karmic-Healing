//
// Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Common
import Onboarding
import Home

@Reducer
struct KarmicHealing {
  @Dependency(\.userDefaults) var userDefaults

  @ObservableState
  struct State {
    var destination: Destination.State = .onboarding(.init())
    var selectedReminderID: UUID? = nil
  }

  enum Action {
    case onDidFinishLaunching
    case destination(Destination.Action)
    case setSelectedReminderID(UUID?)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onDidFinishLaunching:
        if shouldShowOnboarding() {
          state.destination = .home(.init())
        }
        return .none
                
      case .destination(.onboarding(.completeOnboarding)):
        state.destination = .home(.init())
        return .none

      case .destination:
        return .none
        
      case .setSelectedReminderID(let id):
        state.selectedReminderID = id
        return .none
      }
    }
    .ifLet(\.destination.onboarding, action: \.destination.onboarding) { Onboarding() }
    .ifLet(\.destination.home, action: \.destination.home) { Home() }
  }
}

@Reducer(state: .equatable, action: .equatable)
enum Destination {
  case onboarding(Onboarding)
  case home(Home)
}

extension KarmicHealing {
  fileprivate func shouldShowOnboarding() -> Bool {
    return userDefaults.bool(for: .showedOnboarding)
  }
}
