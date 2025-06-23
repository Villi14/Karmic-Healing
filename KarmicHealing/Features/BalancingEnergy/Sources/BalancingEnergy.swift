//
// Karmic Healing 2025
//

import ComposableArchitecture

@Reducer
public struct BalancingEnergy {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    let title: String
    var currentStep: Int
    var isCompleted: Bool
    let steps: [Step]

    public init(
      title: String,
      currentStep: Int,
      isCompleted: Bool,
      steps: [Step]
    ) {
      self.title = title
      self.currentStep = currentStep
      self.isCompleted = isCompleted
      self.steps = steps
    }
  }

  public enum Action: Equatable {
    case nextStep
    case previousStep
    case completeSteps
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .nextStep:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
        } else {
          return .send(.completeSteps)
        }
        return .none

      case .previousStep:
        if state.currentStep > 0 {
          state.currentStep -= 1
        }
        return .none

      case .completeSteps:
        state.isCompleted = true
        return .none
      }
    }
  }
}
