//
//   Karmic Healing 2025
//

import Foundation
import ComposableArchitecture

@Reducer
public struct Reminders {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public init() {}
    public var selectedReminderID: UUID? = nil
  }
  
  public enum Action: Equatable {
    case setSelectedReminderID(UUID?)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .setSelectedReminderID(let id):
        state.selectedReminderID = id
        return .none
      }
    }
  }
}
