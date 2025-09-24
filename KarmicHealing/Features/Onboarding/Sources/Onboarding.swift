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
      steps: [OnboardingStep] = [ .firstStep, .secondStep, .thirdStep, .fourthStep ]
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
      await userDefaults.setAsync(true, for: .showedOnboarding)
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
      imageName: "book.closed",
      title: "onboarding_book_title".loc,
      description: "onboarding_book_description".loc,
      showSkipButton: true
    )
  }
  
  public static var secondStep: Self {
    .init(
      imageName: "sparkles",
      title: "onboarding_app_title".loc,
      description: "onboarding_app_description".loc
    )
  }
  
  public static var thirdStep: Self {
    .init(
      imageName: "heart",
      title: "onboarding_healing_title".loc,
      description: "onboarding_healing_description".loc
    )
  }
  
  public static var fourthStep: Self {
    .init(
      imageName: "star",
      title: "onboarding_journey_title".loc,
      description: "onboarding_journey_description".loc
    )
  }
}

