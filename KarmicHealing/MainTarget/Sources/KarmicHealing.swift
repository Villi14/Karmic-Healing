//
// Karmic Healing 2025
//

import Foundation
@preconcurrency import ComposableArchitecture
import Common
import Onboarding
import Home

@Reducer
struct KarmicHealing {
  @Dependency(\.userDefaults) var userDefaults
  @Dependency(\.notification) var notification

  @ObservableState
  struct State: Equatable {
    var destination: Destination.State = .onboarding(.init())
    var selectedReminderID: UUID? = nil
  }

  enum Action: Equatable {
    case onDidFinishLaunching
    case destination(Destination.Action)
    case setSelectedReminderID(UUID?)
  }

  var body: some ReducerOf<Self> {
    // `destination` is non-optional, so it is scoped rather than `ifLet`-ed.
    Scope(state: \.destination, action: \.destination) {
      Destination.body
    }
    Reduce { state, action in
      switch action {
      case .onDidFinishLaunching:
        if shouldShowOnboarding() {
          state.destination = .home(.init())
        }
        // Sessions no longer schedule anything, but a device updated from a build that did still
        // carries the tail, and it would keep firing with the app closed.
        return .run { _ in notification.purgeSessionNotifications() }
                
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
  }
}

@Reducer
enum Destination {
  case onboarding(Onboarding)
  case home(Home)
}

extension Destination.State: Equatable {}
extension Destination.Action: Equatable {}


extension KarmicHealing {
  fileprivate func shouldShowOnboarding() -> Bool {
    return userDefaults.bool(for: .showedOnboarding)
  }
}
