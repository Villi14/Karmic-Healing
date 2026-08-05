//
// Karmic Healing 2025
//

import ComposableArchitecture
import Foundation
import XCTest
@testable import Db

@MainActor
final class RemindersFeatureTests: XCTestCase {
  func testSelectedReminderIDStartsEmpty() {
    let state = Reminders.State()

    XCTAssertNil(state.selectedReminderID)
    XCTAssertNil(state.selectedReminderListID)
  }

  func testSetSelectedReminderIDStoresTheIdentifier() async {
    let reminderID = UUID()
    let store = TestStore(initialState: Reminders.State()) {
      Reminders()
    }

    await store.send(.setSelectedReminderID(reminderID)) {
      $0.selectedReminderID = reminderID
    }
  }

  func testSetSelectedReminderIDClearsTheIdentifier() async {
    var initialState = Reminders.State()
    initialState.selectedReminderID = UUID()

    let store = TestStore(initialState: initialState) {
      Reminders()
    }

    await store.send(.setSelectedReminderID(nil)) {
      $0.selectedReminderID = nil
    }
  }
}
