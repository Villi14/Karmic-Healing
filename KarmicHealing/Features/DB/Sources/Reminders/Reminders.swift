//
//   Karmic Healing 2025
//

import ComposableArchitecture

@Reducer
public struct Reminders {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }
  
  public enum Action: Equatable {}
  
  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
}
