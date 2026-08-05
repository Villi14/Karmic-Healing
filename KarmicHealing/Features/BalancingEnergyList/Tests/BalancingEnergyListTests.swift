//
// Karmic Healing 2025
//

import Common
import ComposableArchitecture
import XCTest
@testable import BalancingEnergyList

@MainActor
final class BalancingEnergyListTests: XCTestCase {
  func testOnAppearReadsInitialProcessFlag() async {
    let store = TestStore(initialState: BalancingEnergyList.State()) {
      BalancingEnergyList()
    } withDependencies: {
      $0.userDefaults.boolForKey = { key in key == "initial_process_completed" }
    }

    await store.send(.onAppear) {
      $0.initialProcessCompleted = true
    }
  }

  func testOnAppearKeepsFlagFalseWhenNothingStored() async {
    let store = TestStore(initialState: BalancingEnergyList.State()) {
      BalancingEnergyList()
    } withDependencies: {
      $0.userDefaults.boolForKey = { _ in false }
    }

    await store.send(.onAppear)
  }

  /// The three meditations are pure signals: the parent reacts to them by pushing the
  /// matching screen, the list itself keeps its state untouched.
  func testMeditationActionsAreSignalsWithoutStateChanges() async {
    let store = TestStore(initialState: BalancingEnergyList.State()) {
      BalancingEnergyList()
    }

    await store.send(.initialProcess)
    await store.send(.essentialSelf)
    await store.send(.divineSelf)

    XCTAssertEqual(store.state, BalancingEnergyList.State())
  }

  func testHelpIsPresentedAndDismissed() async {
    let store = TestStore(initialState: BalancingEnergyList.State()) {
      BalancingEnergyList()
    }

    await store.send(.helpButtonTapped) {
      $0.help = BalancingEnergyHelp.State(isPresented: true)
    }
    await store.send(.helpDismissed) {
      $0.help = nil
    }
  }

  func testHelpChildDismissClosesTheSheet() async {
    let store = TestStore(
      initialState: BalancingEnergyList.State()
    ) {
      BalancingEnergyList()
    }

    await store.send(.helpButtonTapped) {
      $0.help = BalancingEnergyHelp.State(isPresented: true)
    }
    await store.send(.help(.presented(.dismissButtonTapped)))
    await store.receive(.help(.presented(.dismiss))) {
      $0.help = nil
    }
  }

  func testMarkInitialProcessCompletedSetsTheFlag() async {
    let store = TestStore(initialState: BalancingEnergyList.State()) {
      BalancingEnergyList()
    }

    await store.send(.markInitialProcessCompleted) {
      $0.initialProcessCompleted = true
    }
  }
}
