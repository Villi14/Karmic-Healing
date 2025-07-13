//
// Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Home
import Common
import Onboarding

@Reducer
struct KarmicHealing {
  @Dependency(\.userDefaults) var userDefaults
  @Dependency(\.context) var context

  @ObservableState
  struct State {
    var destination: Destination.State = .onboarding(.init())
  }

  enum Action {
    case onDidFinishLaunching
    case destination(Destination.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onDidFinishLaunching:
        if shouldShowOnboarding() {
          state.destination = .home(.init())
        }

        if context == .live {
          try! prepareDependencies {
            $0.defaultDatabase = try appDatabase()
          }
        }
        return .none
                
      case .destination(.onboarding(.completeOnboarding)):
        state.destination = .home(.init())
        return .none

      case .destination:
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
    return userDefaults.bool(for: BoolKey.showedOnboarding)
  }
}
