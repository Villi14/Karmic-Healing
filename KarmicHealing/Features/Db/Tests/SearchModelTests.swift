//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import SQLiteData
import XCTest
@testable import Db

final class SearchModelTests: XCTestCase {
  private var database: (any DatabaseWriter)!
  private let remindersListID = UUID()
  private let requestsListID = UUID()

  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try appDatabase()

    try database.write { [remindersListID, requestsListID] db in
      try RemindersList.insert { RemindersList(id: remindersListID, title: "Personal") }.execute(db)
      try Reminder.insert {
        Reminder.Draft(notes: "Every morning", remindersListID: remindersListID, title: "Morning meditation")
        Reminder.Draft(notes: "Breathe deeply", remindersListID: remindersListID, title: "Evening walk")
      }
      .execute(db)

      try RequestsList.insert { RequestsList(id: requestsListID, title: "Family") }.execute(db)
      try Request.insert {
        Request.Draft(notes: "Ask for guidance", requestsListID: requestsListID, title: "Healing request")
        Request.Draft(notes: "Nothing special", requestsListID: requestsListID, title: "Gratitude")
      }
      .execute(db)
    }
  }

  override func tearDown() {
    database = nil
    super.tearDown()
  }

  func testSearchingRemindersMatchesTitle() throws {
    let results = try database.read { try Reminder.searching("meditation").fetchAll($0) }
    XCTAssertEqual(results.map(\.title), ["Morning meditation"])
  }

  func testSearchingRemindersMatchesNotes() throws {
    let results = try database.read { try Reminder.searching("breathe").fetchAll($0) }
    XCTAssertEqual(results.map(\.title), ["Evening walk"])
  }

  func testSearchingRemindersIsCaseInsensitive() throws {
    let results = try database.read { try Reminder.searching("MORNING").fetchAll($0) }
    XCTAssertEqual(Set(results.map(\.title)), ["Morning meditation"])
  }

  func testSearchingRemindersWithoutMatchesReturnsNothing() throws {
    let results = try database.read { try Reminder.searching("nonexistent").fetchAll($0) }
    XCTAssertTrue(results.isEmpty)
  }

  func testSearchingRequestsMatchesTitleAndNotes() throws {
    let byTitle = try database.read { try Request.searching("healing").fetchAll($0) }
    XCTAssertEqual(byTitle.map(\.title), ["Healing request"])

    let byNotes = try database.read { try Request.searching("guidance").fetchAll($0) }
    XCTAssertEqual(byNotes.map(\.title), ["Healing request"])
  }

  func testSearchingRequestsListsMatchesDescriptionAndNotes() throws {
    let listID = UUID()
    try database.write { db in
      try RequestsList.insert {
        RequestsList(
          id: listID,
          title: "Business",
          description: "Money flow",
          notes: "Written in the evening"
        )
      }
      .execute(db)
    }

    XCTAssertEqual(
      try database.read { try RequestsList.searching("money").fetchAll($0) }.map(\.title),
      ["Business"]
    )
    XCTAssertEqual(
      try database.read { try RequestsList.searching("evening").fetchAll($0) }.map(\.title),
      ["Business"]
    )
    XCTAssertEqual(
      try database.read { try RequestsList.searching("family").fetchAll($0) }.map(\.title),
      ["Family"]
    )
  }

  func testSearchingIgnoresCaseInUkrainian() throws {
    let listID = UUID()
    try database.write { db in
      try RequestsList.insert {
        RequestsList(id: listID, title: "Здоров'я", notes: "Прохання про зцілення")
      }
      .execute(db)
      try Request.insert {
        Request.Draft(requestsListID: listID, title: "Подякувати Володарям Карми")
      }
      .execute(db)
    }

    XCTAssertEqual(
      try database.read { try RequestsList.searching("здоров'я").fetchAll($0) }.map(\.title),
      ["Здоров'я"]
    )
    XCTAssertEqual(
      try database.read { try RequestsList.searching("ПРОХАННЯ").fetchAll($0) }.map(\.title),
      ["Здоров'я"]
    )
    XCTAssertEqual(
      try database.read { try Request.searching("володарям").fetchAll($0) }.map(\.title),
      ["Подякувати Володарям Карми"]
    )
  }

  func testSearchingRemindersIgnoresCaseInUkrainian() throws {
    try database.write { [remindersListID] db in
      try Reminder.insert {
        Reminder.Draft(remindersListID: remindersListID, title: "Ранкова Медитація")
      }
      .execute(db)
    }

    XCTAssertEqual(
      try database.read { try Reminder.searching("медитація").fetchAll($0) }.map(\.title),
      ["Ранкова Медитація"]
    )
  }

  func testEmptySearchTextMatchesEverything() throws {
    let results = try database.read { try Reminder.searching("").fetchAll($0) }
    XCTAssertEqual(results.count, 2)
  }
}
