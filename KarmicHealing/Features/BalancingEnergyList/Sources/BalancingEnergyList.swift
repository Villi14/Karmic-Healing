//
//   Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import BalancingEnergy

@Reducer
public struct BalancingEnergyList {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {
    case initialProcess
    case essentialSelf
    case divineSelf
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .initialProcess, .essentialSelf, .divineSelf:
        return .none
      }
    }
  }
}
