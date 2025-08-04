//
// Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Resources
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
      .balancingEnуergyButton,
      .requestsButton,
      .remindersButton,
      .settingsButton
    ]
  }

  public enum Action: Equatable {
    case didTap(HomeButton)
    case path(StackActionOf<Path>)
    case openReminderFormFromNotification(reminderID: UUID? = nil)
    case resetNavigationAndOpenReminder(reminderID: UUID? = nil)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didTap(button):
        switch button {
        case .balancingEnуergyButton:
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
        state.path.append(
          .balancingEnergy(
            .init(
              title: String(localized: "initial_process", bundle: .main),
              currentStep: 0,
              isCompleted: false,
              steps: Step.part1
            )
          )
        )
        return .none
      case .path(.element(id: _, action: .balancingEnergyList(.essentialSelf))):
        state.path.append(
          .balancingEnergy(
            .init(
              title: String(localized: "essential_self", bundle: .main),
              currentStep: 0,
              isCompleted: false,
              steps: Step.part2
            )
          )
        )
        return .none
      case .path(.element(id: _, action: .balancingEnergyList(.divineSelf))):
        state.path.append(
          .balancingEnergy(
            .init(
              title: String(localized: "divine_self", bundle: .main),
              currentStep: 0,
              isCompleted: false,
              steps: Step.part3
            )
          )
        )
        return .none
      case .path:
        return .none
      case let .openReminderFormFromNotification(reminderID):
        // Open RemindersView and set selectedReminderID
        var remindersState = Reminders.State()
        remindersState.selectedReminderID = reminderID
        state.path.append(.reminders(remindersState))
        return .none
        
      case let .resetNavigationAndOpenReminder(reminderID):
        // Reset all navigation and open RemindersDetailView
        state.path.removeAll()
        var remindersState = Reminders.State()
        remindersState.selectedReminderID = reminderID
        state.path.append(.reminders(remindersState))
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}

@Reducer(state: .equatable, action: .equatable)
public enum Path {
  case balancingEnergyList(BalancingEnergyList)
  case balancingEnergy(BalancingEnergy)
  case requests(Requests)
  case reminders(Reminders)
  case appSettings(AppSettings)
}
