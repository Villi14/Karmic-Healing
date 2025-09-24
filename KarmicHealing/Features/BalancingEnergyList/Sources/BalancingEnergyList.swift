//
//   Karmic Healing 2025
//

import ComposableArchitecture
import BalancingEnergy

@Reducer
public struct BalancingEnergyList {
  @Dependency(\.userDefaults) var userDefaults
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var initialProcessCompleted: Bool = false
    public var isHelpPresented: Bool = false

    @Presents public var help: BalancingEnergyHelp.State?
    @Presents public var balancingEnergy: BalancingEnergy.State?

    public init(initialProcessCompleted: Bool = false) {
      self.initialProcessCompleted = initialProcessCompleted
    }
  }

  public enum Action: Equatable {
    case onAppear
    case initialProcess
    case essentialSelf
    case divineSelf
    case markInitialProcessCompleted
    case helpButtonTapped
    case helpDismissed
    case help(PresentationAction<BalancingEnergyHelp.Action>)
    case balancingEnergy(PresentationAction<BalancingEnergy.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.initialProcessCompleted = userDefaults.bool(for: .initialProcessCompleted)
        return .none
      case .markInitialProcessCompleted:
        state.initialProcessCompleted = true
        return .none
      case .helpButtonTapped:
        state.help = BalancingEnergyHelp.State(isPresented: true)
        return .none
      case .helpDismissed:
        state.help = nil
        return .none
      case .help(.presented(.dismiss)):
        state.help = nil
        return .none
      case .initialProcess:
        state.balancingEnergy = BalancingEnergy.State(
          title: "Initial Process",
          currentStep: 0,
          isCompleted: false,
          steps: Step.part1
        )
        return .none
      case .essentialSelf:
        state.balancingEnergy = BalancingEnergy.State(
          title: "Essential Self",
          currentStep: 0,
          isCompleted: false,
          steps: Step.part2
        )
        return .none
      case .divineSelf:
        state.balancingEnergy = BalancingEnergy.State(
          title: "Divine Self",
          currentStep: 0,
          isCompleted: false,
          steps: Step.part3
        )
        return .none
      case .balancingEnergy(.presented(.completeSteps)):
        let wasInitialProcess = state.balancingEnergy?.title == "Initial Process"
        state.balancingEnergy = nil
        if wasInitialProcess {
          return .send(.markInitialProcessCompleted)
        }
        return .none
      case .help, .balancingEnergy:
        return .none
      }
    }
    .ifLet(\.$help, action: \.help) {
      BalancingEnergyHelp()
    }
    .ifLet(\.$balancingEnergy, action: \.balancingEnergy) {
      BalancingEnergy()
    }
  }
}
