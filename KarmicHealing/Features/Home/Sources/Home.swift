//
// Karmic Healing 2025
//

import Foundation
@preconcurrency import ComposableArchitecture
import Common
import AppSettings
import Db
import BalancingEnergyList
import BalancingEnergy

@Reducer
public struct Home {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    public init() {}
    
    var path = StackState<Path.State>()
    
    let homeButtons: [HomeButton] = [
      .balancingEnergyButton,
      .requestsButton,
      .remindersButton,
      .settingsButton
    ]
  }
  
  public enum Action: Equatable {
    case didTap(HomeButton)
    case path(StackActionOf<Path>)
    case openReminderFormFromNotification(reminderID: UUID? = nil)
    case resetNavigationAndOpenReminder(reminderID: UUID? = nil, reminderListID: UUID? = nil)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didTap(button):
        switch button {
        case .balancingEnergyButton:
          state.path.append(.balancingEnergyList(.init()))
          return .none
        case .requestsButton:
          state.path.append(.requests(.init()))
          return .none
        case .remindersButton:
          state.path.append(.reminders(.init()))
          return .none
        case .settingsButton:
          state.path.append(.appSettings(.init()))
          return .none
        default:
          return .none
        }
      case .path(.element(id: _, action: .balancingEnergyList(.initialProcess))):
        state.path.append(.balancingEnergy(.start(.initialProcess)))
        return .none
      case .path(.element(id: _, action: .balancingEnergy(.completeSteps))):
        // After completion return to list; list reducer will re-read the flag itself
        return .none
      case .path(.element(id: _, action: .balancingEnergy(.initialProcessCompletionSaved))):
        // After completion stay on list but update its state
        // Find BalancingEnergyList in stack and send action for update
        for index in state.path.indices {
          if case .balancingEnergyList = state.path[index] {
            return .send(.path(.element(id: state.path.ids[index], action: .balancingEnergyList(.markInitialProcessCompleted))))
          }
        }
        return .none
      case .path(.element(id: _, action: .balancingEnergyList(.essentialSelf))):
        state.path.append(.balancingEnergy(.start(.essentialSelf)))
        return .none
      case .path(.element(id: _, action: .balancingEnergyList(.divineSelf))):
        state.path.append(.balancingEnergy(.start(.divineSelf)))
        return .none

      case let .openReminderFormFromNotification(reminderID):
        // Open RemindersView and set selectedReminderID
        var remindersState = Reminders.State()
        remindersState.selectedReminderID = reminderID
        state.path.append(.reminders(remindersState))
        return .none
        
      case let .resetNavigationAndOpenReminder(reminderID, reminderListID):
        // Reset all navigation and open RemindersDetailView
        state.path.removeAll()
        var remindersState = Reminders.State()
        remindersState.selectedReminderID = reminderID
        remindersState.selectedReminderListID = reminderListID
        state.path.append(.reminders(remindersState))
        return .none
        
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

@Reducer
public enum Path {
  case balancingEnergyList(BalancingEnergyList)
  case balancingEnergy(BalancingEnergy)
  case requests(Requests)
  case reminders(Reminders)
  case appSettings(AppSettings)
}

extension Path.State: Equatable {}
extension Path.Action: Equatable {}
