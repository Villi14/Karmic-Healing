//
//   Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Common

@Reducer
public struct Requests {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {}

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in  .none }
  }
}
