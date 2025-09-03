//
//   Karmic Healing 2025
//

import ComposableArchitecture
import BalancingEnergy

@Reducer
public struct BalancingEnergyList {
  @Dependency(\.userDefaults) var userDefaults
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var initialProcessCompleted: Bool = false
    public init(initialProcessCompleted: Bool = false) {
      self.initialProcessCompleted = initialProcessCompleted
    }
  }

  public enum Action: Equatable {
    case onAppear
    case initialProcess
    case essentialSelf
    case divineSelf
    case markInitialProcessCompleted
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.initialProcessCompleted = userDefaults.bool(for: .initialProcessCompleted)
        return .none
      case .markInitialProcessCompleted:
        state.initialProcessCompleted = true
        return .none
      case .initialProcess, .essentialSelf, .divineSelf:
        return .none
      }
    }
  }
}
