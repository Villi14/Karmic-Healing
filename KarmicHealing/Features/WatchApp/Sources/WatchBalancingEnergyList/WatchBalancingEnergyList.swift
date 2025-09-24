//
//   Karmic Healing 2025
//

import ComposableArchitecture
import Foundation

public enum MeditationType: String, CaseIterable {
  case essential = "essential_self"
  case divine = "divine_self"
}

@Reducer
public struct WatchBalancingEnergyList {
  @Dependency(\.watchUserDefaults) var userDefaults
  @Dependency(\.watchNotification) var notification
  public init() {}

  private func getMeditationData(for meditationType: MeditationType) -> (String, [Step]) {
    print("WatchBalancingEnergyList: getMeditationData for meditationType: '\(meditationType.rawValue)'")

    switch meditationType {
    case .essential:
      print("WatchBalancingEnergyList: Returning essential_self with \(Step.part2.count) steps")
      return ("essential_self", Step.part2)
    case .divine:
      print("WatchBalancingEnergyList: Returning divine_self with \(Step.part3.count) steps")
      return ("divine_self", Step.part3)
    }
  }

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
    case handlePushNotification(currentStep: Int, processTitle: String)
    case handleNotificationTap(processTitle: String, currentStep: Int)
    case balancingEnergy(PresentationAction<WatchBalancingEnergy.Action>)
    case settings(PresentationAction<WatchSettings.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
      case .essentialSelf:
        let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
        let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
        state.balancingEnergy = WatchBalancingEnergy.State(
          title: "essential_self",
          currentStep: 0,
          isCompleted: false,
          steps: Step.part2,
          remainingTime: sessionDuration * 60
        )
        // Save meditation type
        return .run { _ in
          await userDefaults.setString(MeditationType.essential.rawValue, StringKey.activeMeditationType.rawValue)
        }
      case .divineSelf:
        let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
        let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
        state.balancingEnergy = WatchBalancingEnergy.State(
          title: "divine_self",
          currentStep: 0,
          isCompleted: false,
          steps: Step.part3,
          remainingTime: sessionDuration * 60
        )
        // Save meditation type
        return .run { _ in
          await userDefaults.setString(MeditationType.divine.rawValue, StringKey.activeMeditationType.rawValue)
        }
      case .openSettings:
        state.settings = WatchSettings.State.withLoadedSettings(userDefaults: userDefaults)
        return .none
      case .settings:
        return .none
      case let .handlePushNotification(currentStep, processTitle):
        // Open the correct meditation at the correct step
        // Get the correct meditation data based on processTitle
        guard let meditationType = MeditationType(rawValue: processTitle) else {
          print("WatchBalancingEnergyList: Invalid meditation type: \(processTitle)")
          return .none
        }
        let (title, steps) = getMeditationData(for: meditationType)

        // Open the meditation at the current step
        state.balancingEnergy = WatchBalancingEnergy.State(
          title: title,
          currentStep: currentStep,
          isCompleted: false,
          steps: steps
        )
        return .none

      case let .handleNotificationTap(processTitle, currentStep):
        // Handle notification tap - open the specific meditation at the specific step
        print("WatchBalancingEnergyList: Handling notification tap - processTitle: \(processTitle), currentStep: \(currentStep)")
        // Cancel any pending notifications to avoid duplicate wakes
        notification.cancelBalancingEnergyNotifications()
        // Use the saved meditation type instead of trying to guess from processTitle
        let meditationTypeString = userDefaults.string(for: StringKey.activeMeditationType) ?? processTitle
        guard let meditationType = MeditationType(rawValue: meditationTypeString) else {
          print("WatchBalancingEnergyList: Invalid meditation type: \(meditationTypeString)")
          return .none
        }
        
        let (title, steps) = getMeditationData(for: meditationType)
        let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
        let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration

        print("WatchBalancingEnergyList: Opening meditation - title: \(title), steps: \(steps.count), currentStep: \(currentStep)")
        state.balancingEnergy = WatchBalancingEnergy.State(
          title: title,
          currentStep: currentStep,
          isCompleted: false,
          steps: steps,
          remainingTime: sessionDuration * 60
        )
        // Don't trigger autoScrollTimer - notification already opens the correct step
        return .none
      case .balancingEnergy(.presented(.completeSteps)):
        // Clear meditation state when completed
        state.balancingEnergy = nil
        return .run { _ in
          await userDefaults.setAsync(false, for: .hasActiveMeditation)
        }
      case .balancingEnergy:
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

