//
// Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Resources
import Common
import SwiftUICore
import AppSettings
import Requests
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
      .notesButton,
      .settingsButton
    ]
  }

  public enum Action: Equatable {
    case didTap(HomeButton)
    case path(StackActionOf<Path>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .didTap(button):
        switch button {
        case .settingsButton:
          state.path.append(.appSettings(.init()))
          return .none
        case .requestsButton:
          state.path.append(.requests(.init(title: String(localized: "requests", bundle: .main))))
          return .none
        case .balancingEnуergyButton:
          state.path.append(.balancingEnergyList(.init()))
          return .none
        case .notesButton:
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
      }
    }
    .forEach(\.path, action: \.path)
  }
}

@Reducer(state: .equatable, action: .equatable)
public enum Path {
  case appSettings(AppSettings)
  case requests(Requests)
  case balancingEnergyList(BalancingEnergyList)
  case balancingEnergy(BalancingEnergy)
}
