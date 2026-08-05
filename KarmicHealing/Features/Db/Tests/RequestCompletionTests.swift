//
// Karmic Healing 2025
//

import Foundation
import GRDB
import SQLiteData
import XCTest
@testable import Db

final class RequestCompletionTests: XCTestCase {
  private var database: (any DatabaseWriter)!

  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try appDatabase()
  }

  override func tearDown() {
    database = nil
    super.tearDown()
  }

  // MARK: - A request without subrequests

  func testRequestWithoutSubrequestsCanBeFulfilledStraightAway() throws {
    let request = try makeRequest(subrequests: [])

    XCTAssertTrue(canToggle(request))
    XCTAssertTrue(try toggle(request))
    XCTAssertTrue(try isFulfilled(request))
  }

  func testRequestWithoutSubrequestsCanBeReopened() throws {
    let request = try makeRequest(isCompleted: true, subrequests: [])

    XCTAssertFalse(try toggle(request))
    XCTAssertFalse(try isFulfilled(request))
  }

  // MARK: - A request waiting on its subrequests

  func testRequestStaysLockedWhileASubrequestIsUnfulfilled() throws {
    let request = try makeRequest(subrequests: [("First", true), ("Second", false)])

    XCTAssertFalse(canToggle(request))
    XCTAssertFalse(try toggle(request))
    XCTAssertFalse(try isFulfilled(request))
  }

  func testRequestUnlocksOnceEverySubrequestIsFulfilled() throws {
    let request = try makeRequest(subrequests: [("First", true), ("Second", false)])

    try fulfillEverySubrequest(of: request)

    XCTAssertTrue(canToggle(request))
    XCTAssertTrue(try toggle(request))
    XCTAssertTrue(try isFulfilled(request))
  }

  func testFulfillingTheLastSubrequestDoesNotFulfillTheRequestItself() throws {
    let request = try makeRequest(subrequests: [("First", true), ("Second", false)])

    try fulfillEverySubrequest(of: request)
    try database.write { db in
      try RequestsList.syncCompletion(of: request.id, in: db)
    }

    XCTAssertFalse(try isFulfilled(request), "The user taps the radio button; nothing closes on its own")
  }

  func testFulfillingTheRequestLeavesItsSubrequestsUntouched() throws {
    let request = try makeRequest(subrequests: [("First", true), ("Second", true)])

    XCTAssertTrue(try toggle(request))

    let subrequests = try database.read { db in
      try Request.where { $0.requestsListID.eq(request.id) }.fetchAll(db)
    }
    XCTAssertEqual(subrequests.count, 2)
    XCTAssertTrue(subrequests.allSatisfy(\.isCompleted))
  }

  // MARK: - Reopening a fulfilled request

  func testFulfilledRequestCanAlwaysBeReopened() throws {
    let request = try makeRequest(isCompleted: true, subrequests: [("First", false)])

    XCTAssertTrue(canToggle(request), "Clearing the radio button is never blocked")
    XCTAssertFalse(try toggle(request))
    XCTAssertFalse(try isFulfilled(request))
  }

  func testReopeningASubrequestReopensTheRequest() throws {
    let request = try makeRequest(subrequests: [("First", true), ("Second", true)])
    XCTAssertTrue(try toggle(request))

    try database.write { db in
      try Request
        .where { $0.requestsListID.eq(request.id) && $0.title.eq("First") }
        .update { $0.isCompleted = false }
        .execute(db)
      try RequestsList.syncCompletion(of: request.id, in: db)
    }

    XCTAssertFalse(try isFulfilled(request))
  }

  func testANewSubrequestReopensAFulfilledRequest() throws {
    let request = try makeRequest(subrequests: [("First", true)])
    XCTAssertTrue(try toggle(request))

    try database.write { db in
      try Request.insert {
        Request.Draft(requestsListID: request.id, title: "Second")
      }
      .execute(db)
      try RequestsList.syncCompletion(of: request.id, in: db)
    }

    XCTAssertFalse(try isFulfilled(request))
    XCTAssertFalse(canToggle(request))
  }

  func testAFulfilledSubrequestLeavesAFulfilledRequestAlone() throws {
    let request = try makeRequest(subrequests: [("First", true)])
    XCTAssertTrue(try toggle(request))

    try database.write { db in
      try Request.insert {
        Request.Draft(isCompleted: true, requestsListID: request.id, title: "Second")
      }
      .execute(db)
      try RequestsList.syncCompletion(of: request.id, in: db)
    }

    XCTAssertTrue(try isFulfilled(request))
  }

  func testDeletingTheLastUnfulfilledSubrequestUnlocksTheRequest() throws {
    let request = try makeRequest(subrequests: [("First", true), ("Second", false)])
    XCTAssertFalse(canToggle(request))

    try database.write { db in
      try Request
        .where { $0.requestsListID.eq(request.id) && $0.title.eq("Second") }
        .delete()
        .execute(db)
      try RequestsList.syncCompletion(of: request.id, in: db)
    }

    XCTAssertFalse(try isFulfilled(request), "Deleting a subrequest unlocks the request, it does not fulfil it")
    XCTAssertTrue(canToggle(request))
  }

  func testDeletingEverySubrequestUnlocksTheRequest() throws {
    let request = try makeRequest(subrequests: [("First", false), ("Second", false)])

    try database.write { db in
      try Request.where { $0.requestsListID.eq(request.id) }.delete().execute(db)
      try RequestsList.syncCompletion(of: request.id, in: db)
    }

    XCTAssertTrue(canToggle(request))
    XCTAssertTrue(try toggle(request))
  }

  // MARK: - Progress

  func testProgressCountsSubrequests() throws {
    let request = try makeRequest(subrequests: [("First", true), ("Second", false)])

    let progress = try database.read { db in
      try RequestsList.subrequestProgress(of: request.id, in: db)
    }

    XCTAssertEqual(progress, SubrequestProgress(total: 2, completed: 1))
    XCTAssertTrue(progress.hasSubrequests)
    XCTAssertFalse(progress.allCompleted)
  }

  func testProgressOfARequestWithoutSubrequestsCountsAsCovered() throws {
    let request = try makeRequest(subrequests: [])

    let progress = try database.read { db in
      try RequestsList.subrequestProgress(of: request.id, in: db)
    }

    XCTAssertFalse(progress.hasSubrequests)
    XCTAssertTrue(progress.allCompleted, "Nothing stands between the user and this request")
  }

  // MARK: - Helpers

  private func makeRequest(
    id: UUID = UUID(),
    isCompleted: Bool = false,
    subrequests: [(title: String, isCompleted: Bool)]
  ) throws -> RequestsList {
    try database.write { db in
      try RequestsList
        .insert { RequestsList(id: id, title: "Request", isCompleted: isCompleted) }
        .execute(db)
      for subrequest in subrequests {
        try Request.insert {
          Request.Draft(
            isCompleted: subrequest.isCompleted,
            requestsListID: id,
            title: subrequest.title
          )
        }
        .execute(db)
      }
    }
    return try reload(id)
  }

  private func reload(_ id: RequestsList.ID) throws -> RequestsList {
    try database.read { db in try RequestsList.find(id).fetchOne(db)! }
  }

  private func isFulfilled(_ request: RequestsList) throws -> Bool {
    try reload(request.id).isCompleted
  }

  /// Mirrors the radio button's enabled state, always read from the request's current row.
  private func canToggle(_ request: RequestsList) -> Bool {
    guard
      let fresh = try? reload(request.id),
      let progress = try? database.read({ db in
        try RequestsList.subrequestProgress(of: request.id, in: db)
      })
    else { return false }
    return RequestsList.canToggleCompletion(fresh, progress: progress)
  }

  /// Mirrors a tap on the radio button, and reports where the request landed.
  @discardableResult
  private func toggle(_ request: RequestsList) throws -> Bool {
    try database.write { db in
      try RequestsList.toggleCompletion(of: request.id, in: db)
    }
  }

  private func fulfillEverySubrequest(of request: RequestsList) throws {
    try database.write { db in
      try Request
        .where { $0.requestsListID.eq(request.id) && !$0.isCompleted }
        .update { $0.isCompleted = true }
        .execute(db)
    }
  }
}
