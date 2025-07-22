//
// Karmic Healing 2025
//

import ComposableArchitecture
import Common

@Reducer
public struct Onboarding {
  @Dependency(\.userDefaults) var userDefaults

  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var isCompleted: Bool
    var currentStep: Int
    let steps: [OnboardingStep]

    public init(
      isCompleted: Bool = false,
      currentStep: Int = 0,
      steps: [OnboardingStep] = [ .firstStep, .secondStep, .thirdStep ]
    ) {
      self.currentStep = currentStep
      self.isCompleted = isCompleted
      self.steps = steps
    }
  }

  public enum Action: Equatable {
    case nextStep
    case previousStep
    case completeOnboarding
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .nextStep:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
        } else {
          saveDidShowOnboarding()
          return .send(.completeOnboarding)
        }
        return .none

      case .previousStep:
        if state.currentStep > 0 {
          state.currentStep -= 1
        }
        return .none

      case .completeOnboarding:
        state.isCompleted = true
        return .none
      }
    }
  }
}

extension Onboarding {
  fileprivate func saveDidShowOnboarding() {
    Task {
      await userDefaults.setAsync(true, for: BoolKey.showedOnboarding)
    }
  }
}

public struct OnboardingStep: Equatable {
  public let imageName: String
  public let title: String
  public let description: String
  public let showSkipButton: Bool

  public init(
    imageName: String, 
    title: String, 
    description: String,
    showSkipButton: Bool = false
  ) {
    self.imageName = imageName
    self.title = title
    self.description = description
    self.showSkipButton = showSkipButton
  }
}

extension OnboardingStep {
  public static var firstStep: Self {
    .init(
      imageName: "sparkles",
      title: String(localized: "welcome_to_karmic_healing", bundle: .main),
      description: String(localized: "welcome_description", bundle: .main),
      showSkipButton: true
    )
  }

  public static var secondStep: Self {
    .init(
      imageName: "heart",
      title: String(localized: "discover_your_path", bundle: .main),
      description: String(localized: "discover_description", bundle: .main)
    )
  }

  public static var thirdStep: Self {
    .init(
      imageName: "star",
      title: String(localized: "start_your_journey", bundle: .main),
      description: String(localized: "journey_description", bundle: .main)
    )
  }
}

