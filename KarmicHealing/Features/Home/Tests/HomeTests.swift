//
// Karmic Healing 2025
//

import BalancingEnergy
import BalancingEnergyList
import Common
import ComposableArchitecture
import Db
import Foundation
import XCTest
@testable import Home

@MainActor
final class HomeTests: XCTestCase {
  func testDidTapSettingsButtonPushesSettings() async {
    let store = TestStore(initialState: Home.State()) {
      Home()
    }

    await store.send(.didTap(.settingsButton)) {
      $0.path.append(.appSettings(.init()))
    }
  }

  func testDidTapFlowButtonsPushMatchingScreens() async {
    let store = TestStore(initialState: Home.State()) {
      Home()
    }

    await store.send(.didTap(.balancingEnergyButton)) {
      $0.path.append(.balancingEnergyList(.init()))
    }
    await store.send(.didTap(.requestsButton)) {
      $0.path.append(.requests(.init()))
    }
    await store.send(.didTap(.remindersButton)) {
      $0.path.append(.reminders(.init()))
    }

    XCTAssertEqual(store.state.path.count, 3)
  }

  func testHomeShowsAllFourButtons() {
    let state = Home.State()

    XCTAssertEqual(state.homeButtons.count, 4)
    XCTAssertEqual(
      state.homeButtons,
      [.balancingEnergyButton, .requestsButton, .remindersButton, .settingsButton]
    )
  }

  func testInitialProcessPushesPartOne() async {
    let store = TestStore(initialState: Home.State()) {
      Home()
    }
    store.exhaustivity = .off

    await store.send(.didTap(.balancingEnergyButton))
    let listID = store.state.path.ids[0]
    await store.send(.path(.element(id: listID, action: .balancingEnergyList(.initialProcess))))

    XCTAssertEqual(store.state.path.count, 2)
    guard case let .balancingEnergy(energyState) = store.state.path[1] else {
      return XCTFail("Expected a balancing energy screen on top of the stack")
    }
    XCTAssertEqual(energyState.kind, .initialProcess)
    XCTAssertEqual(energyState.title, "initial_process".loc)
    XCTAssertEqual(energyState.steps, Step.part1)
    XCTAssertEqual(energyState.currentStep, 0)
  }

  func testEssentialSelfPushesPartTwo() async {
    let store = TestStore(initialState: Home.State()) {
      Home()
    }
    store.exhaustivity = .off

    await store.send(.didTap(.balancingEnergyButton))
    let listID = store.state.path.ids[0]
    await store.send(.path(.element(id: listID, action: .balancingEnergyList(.essentialSelf))))

    guard case let .balancingEnergy(energyState) = store.state.path[1] else {
      return XCTFail("Expected a balancing energy screen on top of the stack")
    }
    XCTAssertEqual(energyState.title, "essential_self".loc)
    XCTAssertEqual(energyState.steps, Step.part2)
  }

  func testDivineSelfPushesPartThree() async {
    let store = TestStore(initialState: Home.State()) {
      Home()
    }
    store.exhaustivity = .off

    await store.send(.didTap(.balancingEnergyButton))
    let listID = store.state.path.ids[0]
    await store.send(.path(.element(id: listID, action: .balancingEnergyList(.divineSelf))))

    guard case let .balancingEnergy(energyState) = store.state.path[1] else {
      return XCTFail("Expected a balancing energy screen on top of the stack")
    }
    XCTAssertEqual(energyState.title, "divine_self".loc)
    XCTAssertEqual(energyState.steps, Step.part3)
  }

  func testOpeningReminderFromNotificationPushesReminders() async {
    let reminderID = UUID()
    let store = TestStore(initialState: Home.State()) {
      Home()
    }

    var expected = Reminders.State()
    expected.selectedReminderID = reminderID

    await store.send(.openReminderFormFromNotification(reminderID: reminderID)) {
      $0.path.append(.reminders(expected))
    }
  }

  func testResetNavigationClearsTheStackBeforeOpeningReminder() async {
    let reminderID = UUID()
    let reminderListID = UUID()
    let store = TestStore(initialState: Home.State()) {
      Home()
    }

    await store.send(.didTap(.requestsButton)) {
      $0.path.append(.requests(.init()))
    }

    var expected = Reminders.State()
    expected.selectedReminderID = reminderID
    expected.selectedReminderListID = reminderListID

    await store.send(
      .resetNavigationAndOpenReminder(reminderID: reminderID, reminderListID: reminderListID)
    ) {
      $0.path.removeAll()
      $0.path.append(.reminders(expected))
    }

    XCTAssertEqual(store.state.path.count, 1)
  }
}
