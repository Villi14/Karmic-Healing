//
// Karmic Healing 2025
//

import Common
import ComposableArchitecture
import ConcurrencyExtras
import Foundation
import XCTest
@testable import KarmicHealing

@MainActor
final class KarmicHealingTests: XCTestCase {
  func testAppStartsOnOnboarding() {
    let state = KarmicHealing.State()

    guard case .onboarding = state.destination else {
      return XCTFail("Expected onboarding to be the initial destination")
    }
    XCTAssertNil(state.selectedReminderID)
  }

  func testLaunchGoesStraightToHomeWhenOnboardingWasShown() async {
    let store = TestStore(initialState: KarmicHealing.State()) {
      KarmicHealing()
    } withDependencies: {
      $0.userDefaults.boolForKey = { key in key == "showed_onboarding" }
    }

    await store.send(.onDidFinishLaunching) {
      $0.destination = .home(.init())
    }
    await store.finish()
  }

  func testLaunchKeepsOnboardingForFirstTimeUsers() async {
    let store = TestStore(initialState: KarmicHealing.State()) {
      KarmicHealing()
    } withDependencies: {
      $0.userDefaults.boolForKey = { _ in false }
    }

    await store.send(.onDidFinishLaunching)
    await store.finish()

    guard case .onboarding = store.state.destination else {
      return XCTFail("Expected to stay on onboarding")
    }
  }

  func testCompletingOnboardingShowsHome() async {
    let store = TestStore(initialState: KarmicHealing.State()) {
      KarmicHealing()
    } withDependencies: {
      $0.userDefaults.setBool = { _, _ in }
    }

    await store.send(.destination(.onboarding(.completeOnboarding))) {
      $0.destination = .home(.init())
    }
  }

  /// A session posts no notifications any more, so anything still pending was queued by an older
  /// build and would fire with the app closed — launching has to sweep it away.
  func testLaunchPurgesLeftoverSessionNotifications() async {
    let purges = LockIsolated(0)

    let store = TestStore(initialState: KarmicHealing.State()) {
      KarmicHealing()
    } withDependencies: {
      $0.userDefaults.boolForKey = { _ in false }
      $0.notification.purgeSessionNotifications = { purges.withValue { $0 += 1 } }
    }

    await store.send(.onDidFinishLaunching)
    await store.finish()

    XCTAssertEqual(purges.value, 1)
  }

  func testSetSelectedReminderIDIsStored() async {
    let reminderID = UUID()
    let store = TestStore(initialState: KarmicHealing.State()) {
      KarmicHealing()
    }

    await store.send(.setSelectedReminderID(reminderID)) {
      $0.selectedReminderID = reminderID
    }
  }

  func testSetSelectedReminderIDCanClearTheSelection() async {
    let store = TestStore(
      initialState: KarmicHealing.State(selectedReminderID: UUID())
    ) {
      KarmicHealing()
    }

    await store.send(.setSelectedReminderID(nil)) {
      $0.selectedReminderID = nil
    }
  }
}
