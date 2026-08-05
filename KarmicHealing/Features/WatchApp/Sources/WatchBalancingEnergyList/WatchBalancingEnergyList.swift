//
//   Karmic Healing 2025
//

import ComposableArchitecture
import Foundation

public enum MeditationType: String, CaseIterable {
  case essential = "essential_self"
  case divine = "divine_self"

  public var steps: [Step] {
    switch self {
    case .essential: Step.part2
    case .divine: Step.part3
    }
  }
}

@Reducer
public struct WatchBalancingEnergyList {
  @Dependency(\.watchUserDefaults) var userDefaults
  @Dependency(\.watchNotification) var notification
  @Dependency(\.watchRuntime) var runtime
  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents public var balancingEnergy: WatchBalancingEnergy.State?
    @Presents public var settings: WatchSettings.State?

    public init() {}
  }

  public enum Action: Equatable {
    case onAppear
    case essentialSelf
    case divineSelf
    case openSettings
    case balancingEnergy(PresentationAction<WatchBalancingEnergy.Action>)
    case settings(PresentationAction<WatchSettings.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Sessions no longer schedule anything, but a watch updated from a build that did still
        // carries the tail, and it would keep buzzing with the app closed.
        return .run { _ in notification.purgeSessionNotifications() }

      case .essentialSelf:
        state.balancingEnergy = .start(.essential)
        return .none

      case .divineSelf:
        state.balancingEnergy = .start(.divine)
        return .none

      case .openSettings:
        state.settings = WatchSettings.State.withLoadedSettings(userDefaults: userDefaults)
        return .none

      case .balancingEnergy(.presented(.completeSteps)):
        state.balancingEnergy = nil
        return .none

      case .balancingEnergy(.dismiss):
        // Swiping the session away is the one exit the session reducer never sees: the cover's
        // binding nils the state, and `ifLet` cancels the ticking for us — but the runtime session
        // would keep the display awake for a meditation nobody is in, and the wrist would still
        // offer to resume it.
        return .run { [runtime, userDefaults] _ in
          runtime.stop()
          await userDefaults.setAsync(false, for: .hasActiveMeditation)
        }

      case .balancingEnergy, .settings:
        return .none
      }
    }
    .ifLet(\.$balancingEnergy, action: \.balancingEnergy) {
      WatchBalancingEnergy()
    }
    .ifLet(\.$settings, action: \.settings) {
      WatchSettings()
    }
  }
}

extension WatchBalancingEnergy.State {
  /// A fresh session for `type`, optionally resumed on a given slide.
  ///
  /// The step duration is read by the session itself, so it runs at the pace the user configured.
  public static func start(_ type: MeditationType, at step: Int = 0) -> Self {
    let steps = type.steps
    return .init(
      title: type.rawValue,
      currentStep: min(max(0, step), max(0, steps.count - 1)),
      isCompleted: false,
      steps: steps
    )
  }
}
