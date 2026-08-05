//
// Karmic Healing 2025
//

import Foundation
import GRDB
import SQLiteData
import XCTest
@testable import Db

final class SubrequestDueDateTests: XCTestCase {
  private var database: (any DatabaseWriter)!

  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try appDatabase()
  }

  override func tearDown() {
    database = nil
    super.tearDown()
  }

  func testSubrequestsTakeTheDateOfTheirRequest() throws {
    let dueDate = Date(timeIntervalSince1970: 1_700_000_000)
    let id = try makeRequest(dueDate: dueDate, subrequests: ["First", "Second"])

    try database.write { db in
      try RequestsList.inheritDueDate(of: id, in: db)
    }

    XCTAssertEqual(try subrequestDueDates(of: id), [dueDate, dueDate])
  }

  func testMovingTheRequestsDateMovesItsSubrequests() throws {
    let id = try makeRequest(dueDate: Date(timeIntervalSince1970: 1_700_000_000), subrequests: ["First"])
    try database.write { db in
      try RequestsList.inheritDueDate(of: id, in: db)
    }

    let newDate = Date(timeIntervalSince1970: 1_800_000_000)
    try database.write { db in
      try RequestsList.find(id).update { $0.dueDate = #bind(newDate) }.execute(db)
      try RequestsList.inheritDueDate(of: id, in: db)
    }

    XCTAssertEqual(try subrequestDueDates(of: id), [newDate])
  }

  func testClearingTheRequestsDateClearsItsSubrequests() throws {
    let id = try makeRequest(dueDate: Date(timeIntervalSince1970: 1_700_000_000), subrequests: ["First"])
    try database.write { db in
      try RequestsList.inheritDueDate(of: id, in: db)
    }

    try database.write { db in
      try RequestsList.find(id).update { $0.dueDate = #bind(Date?.none) }.execute(db)
      try RequestsList.inheritDueDate(of: id, in: db)
    }

    XCTAssertEqual(try subrequestDueDates(of: id), [nil])
  }

  func testSubrequestsOfADatelessRequestStayDateless() throws {
    let id = try makeRequest(dueDate: nil, subrequests: ["First"])

    try database.write { db in
      try RequestsList.inheritDueDate(of: id, in: db)
    }

    XCTAssertEqual(try subrequestDueDates(of: id), [nil])
  }

  func testInheritingLeavesOtherRequestsAlone() throws {
    let mine = try makeRequest(dueDate: Date(timeIntervalSince1970: 1_700_000_000), subrequests: ["Mine"])
    let other = try makeRequest(dueDate: nil, subrequests: ["Theirs"])

    try database.write { db in
      try RequestsList.inheritDueDate(of: mine, in: db)
    }

    XCTAssertEqual(try subrequestDueDates(of: other), [nil])
  }

  // MARK: - Helpers

  private func makeRequest(dueDate: Date?, subrequests: [String]) throws -> RequestsList.ID {
    let id = UUID()
    try database.write { db in
      try RequestsList
        .insert { RequestsList(id: id, title: "Request", dueDate: dueDate) }
        .execute(db)
      for title in subrequests {
        try Request.insert { Request.Draft(requestsListID: id, title: title) }.execute(db)
      }
    }
    return id
  }

  private func subrequestDueDates(of id: RequestsList.ID) throws -> [Date?] {
    try database.read { db in
      try Request
        .where { $0.requestsListID.eq(id) }
        .order { $0.title }
        .fetchAll(db)
        .map(\.dueDate)
    }
  }
}
