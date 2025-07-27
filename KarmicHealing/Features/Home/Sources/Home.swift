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
    var selectedReminderID: UUID? = nil

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
    case setSelectedReminderID(UUID?)
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
      case .setSelectedReminderID(let id):
//        state.selectedReminderID = id
//        // Прокидуємо в Reminders, якщо він є у path
//        if let index = state.path.lastIndex(where: { if case .reminders = $0 { return true } else { return false } }) {
//          if case .reminders(var remindersState) = state.path[index] {
//            remindersState.selectedReminderID = id
//              //state.path[index] = .reminders(remindersState)
//          }
//        }
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
