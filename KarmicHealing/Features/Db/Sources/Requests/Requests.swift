//
//   Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Common

/// Navigation-only token: the requests screen is driven entirely by `RequestsListsModel`,
/// but the parent's `Path` enum needs a reducer to name the case.
@Reducer
public struct Requests {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
  }

  public enum Action: Equatable {}

  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}
