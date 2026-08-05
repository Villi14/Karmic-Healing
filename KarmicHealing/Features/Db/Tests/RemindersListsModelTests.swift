//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import SQLiteData
import XCTest
@testable import Db

final class RemindersListsModelTests: XCTestCase {
  private var database: (any DatabaseWriter)!

  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try appDatabase()
  }

  override func tearDown() {
    database = nil
    super.tearDown()
  }

  func testFreshDatabaseHasNoRemindersLists() throws {
    let count = try database.read { try RemindersList.all.fetchCount($0) }
    XCTAssertEqual(count, 0)
  }

  func testInsertingRemindersListAndReminders() throws {
    let listID = UUID()

    try database.write { db in
      try RemindersList.insert { RemindersList(id: listID, title: "Personal") }.execute(db)
      try Reminder.insert {
        Reminder.Draft(remindersListID: listID, title: "Meditate")
        Reminder.Draft(isCompleted: true, remindersListID: listID, title: "Breathe")
      }
      .execute(db)
    }

    let reminders = try database.read { db in
      try Reminder.where { $0.remindersListID.eq(listID) }.fetchAll(db)
    }
    XCTAssertEqual(reminders.count, 2)
    XCTAssertEqual(Set(reminders.map(\.title)), ["Meditate", "Breathe"])
  }

  func testIncompleteScopeFiltersOutCompletedReminders() throws {
    let listID = UUID()

    try database.write { db in
      try RemindersList.insert { RemindersList(id: listID, title: "Personal") }.execute(db)
      try Reminder.insert {
        Reminder.Draft(remindersListID: listID, title: "Meditate")
        Reminder.Draft(isCompleted: true, remindersListID: listID, title: "Breathe")
      }
      .execute(db)
    }

    let incomplete = try database.read { try Reminder.incomplete.fetchAll($0) }
    XCTAssertEqual(incomplete.map(\.title), ["Meditate"])
  }

  func testDeletingListCascadesToItsReminders() throws {
    let listID = UUID()

    try database.write { db in
      try RemindersList.insert { RemindersList(id: listID, title: "Personal") }.execute(db)
      try Reminder.insert { Reminder.Draft(remindersListID: listID, title: "Meditate") }.execute(db)
      try RemindersList.find(listID).delete().execute(db)
    }

    let remainingReminders = try database.read { try Reminder.all.fetchCount($0) }
    XCTAssertEqual(remainingReminders, 0)
  }

  func testScheduledScopeOnlyMatchesRemindersWithADueDate() throws {
    let listID = UUID()

    try database.write { db in
      try RemindersList.insert { RemindersList(id: listID, title: "Personal") }.execute(db)
      try Reminder.insert {
        Reminder.Draft(remindersListID: listID, title: "No due date")
        Reminder.Draft(dueDate: Date(), remindersListID: listID, title: "Scheduled")
      }
      .execute(db)
    }

    let scheduled = try database.read { db in
      try Reminder.where { $0.isScheduled }.fetchAll(db)
    }
    XCTAssertEqual(scheduled.map(\.title), ["Scheduled"])
  }

  func testEachTestDatabaseIsIsolated() throws {
    let other = try appDatabase()

    try database.write { db in
      try RemindersList.insert { RemindersList(id: UUID(), title: "Personal") }.execute(db)
    }

    XCTAssertEqual(try database.read { try RemindersList.all.fetchCount($0) }, 1)
    XCTAssertEqual(try other.read { try RemindersList.all.fetchCount($0) }, 0)
  }
}
