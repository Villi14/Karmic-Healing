//
//   Karmic Healing 2025
//

import Foundation
import ComposableArchitecture

@Reducer
public struct BalancingEnergyHelp {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var isPresented: Bool = false
    
    public init(isPresented: Bool = false) {
      self.isPresented = isPresented
    }
  }
  
  public enum Action: Equatable {
    case onAppear
    case dismissButtonTapped
    case dismiss
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
        
      case .dismissButtonTapped:
        return .send(.dismiss)
        
      case .dismiss:
        return .none
      }
    }
  }
}

