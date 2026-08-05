//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import Sharing
import SQLiteData
import XCTest
@testable import Db

@MainActor
final class RequestsDetailModelTests: XCTestCase {
  private var database: (any DatabaseWriter)!
  private var family: RequestsList!
  private let familyID = UUID()
  private let workID = UUID()
  private let firstStepID = UUID()
  private let secondStepID = UUID()
  private let thirdStepID = UUID()
  private let workStepID = UUID()

  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try appDatabase()

    try database.write { db in
      try RequestsList.insert {
        RequestsList(id: familyID, title: "Family")
        RequestsList(id: workID, title: "Work")
      }
      .execute(db)

      try Request.insert {
        Request.Draft(id: firstStepID, requestsListID: familyID, title: "First step")
        Request.Draft(id: secondStepID, requestsListID: familyID, title: "Second step")
        Request.Draft(
          id: thirdStepID,
          isCompleted: true,
          requestsListID: familyID,
          title: "Third step"
        )
        Request.Draft(id: workStepID, requestsListID: workID, title: "Work step")
      }
      .execute(db)
    }

    family = try database.read { try RequestsList.find(familyID).fetchOne($0) }
  }

  override func tearDown() {
    database = nil
    family = nil
    super.tearDown()
  }

  // MARK: - What each screen shows

  /// A request's own screen is the one place a subrequest can be reached, so it shows the
  /// fulfilled ones too — the way back is nowhere else.
  func testARequestScreenShowsAllOfItsSubrequestsAndNobodyElses() async throws {
    try await withModel(.requestsList(family)) { model in
      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["First step", "Second step", "Third step"]
      )
    }
  }

  func testTheAllScreenHidesFulfilledSubrequests() async throws {
    try await withModel(.all) { model in
      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["First step", "Second step", "Work step"]
      )
    }
  }

  func testTheFulfilledScreenShowsOnlyFulfilledSubrequests() async throws {
    try await withModel(.completed) { model in
      XCTAssertEqual(model.requestRows.map(\.request.title), ["Third step"])
    }
  }

  /// Rows outside a single request's screen name the request they came from, so the join has
  /// to carry it.
  func testEveryRowCarriesTheRequestItBelongsTo() async throws {
    try await withModel(.all) { model in
      XCTAssertEqual(
        model.requestRows.map(\.requestsList.title),
        ["Family", "Family", "Work"]
      )
    }
  }

  func testRowsAreOrderedByPosition() async throws {
    try await database.write { [secondStepID] db in
      try Request.find(secondStepID).update { $0.position = -1 }.execute(db)
    }

    try await withModel(.requestsList(family)) { model in
      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["Second step", "First step", "Third step"]
      )
    }
  }

  // MARK: - Showing what is fulfilled

  func testTheFulfilledScreenStartsOpenAndEveryOtherScreenStartsClosed() async throws {
    try await withModel(.completed) { XCTAssertTrue($0.showCompleted) }
    try await withModel(.all) { XCTAssertFalse($0.showCompleted) }
    try await withModel(.requestsList(family)) { XCTAssertFalse($0.showCompleted) }
  }

  /// The all screen is the list of what is still open, and asking for the fulfilled ones does
  /// not change that — the fulfilled screen is where they live.
  func testAskingForFulfilledSubrequestsLeavesTheAllScreenAlone() async throws {
    try await withModel(.all) { model in
      await model.showCompletedButtonTapped()

      XCTAssertTrue(model.showCompleted)
      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["First step", "Second step", "Work step"]
      )
    }
  }

  /// A request's screen already shows everything, so the toggle cannot take anything away.
  func testTheToggleChangesNothingOnARequestScreen() async throws {
    try await withModel(.requestsList(family)) { model in
      await model.showCompletedButtonTapped()

      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["First step", "Second step", "Third step"]
      )
    }
  }

  /// Closing the toggle on the fulfilled screen asks for what is fulfilled and unfulfilled at
  /// once, so the screen empties — and opening it again brings the rows back.
  func testClosingTheToggleEmptiesTheFulfilledScreen() async throws {
    try await withModel(.completed) { model in
      await model.showCompletedButtonTapped()
      XCTAssertTrue(model.requestRows.isEmpty)

      await model.showCompletedButtonTapped()
      XCTAssertEqual(model.requestRows.map(\.request.title), ["Third step"])
    }
  }

  /// The toggle is remembered per screen, so a request's screen never inherits the answer the
  /// user gave on another one.
  func testEachScreenRemembersTheToggleOnItsOwn() async throws {
    try await withDependencies {
      $0.defaultDatabase = database
      $0.defaultAppStorage = ephemeralAppStorage()
    } operation: {
      let allScreen = RequestsDetailModel(detailType: .all)
      await allScreen.showCompletedButtonTapped()

      let requestScreen = RequestsDetailModel(detailType: .requestsList(family))
      XCTAssertFalse(requestScreen.showCompleted)

      let sameScreenAgain = RequestsDetailModel(detailType: .all)
      XCTAssertTrue(sameScreenAgain.showCompleted, "The screen forgot the answer it was given")
    }
  }

  // MARK: - Reordering

  func testMovingASubrequestUpRenumbersTheWholeScreen() async throws {
    try await withModel(.requestsList(family)) { model in
      await model.move(from: [2], to: 0)

      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["Third step", "First step", "Second step"]
      )
    }

    XCTAssertEqual(try positions(of: [thirdStepID, firstStepID, secondStepID]), [0, 1, 2])
  }

  /// `move(fromOffsets:toOffset:)` reads the destination in the list as it stands before the
  /// row leaves it, so dropping below the last row means an index one past the end.
  func testMovingASubrequestDownLandsItWhereItWasDropped() async throws {
    try await withModel(.requestsList(family)) { model in
      await model.move(from: [0], to: 3)

      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["Second step", "Third step", "First step"]
      )
    }
  }

  /// Positions are numbered across every subrequest in the database, so a move inside one
  /// request must not renumber another request's steps out from under it.
  func testMovingLeavesEveryOtherRequestUntouched() async throws {
    let before = try positions(of: [workStepID])

    try await withModel(.requestsList(family)) { model in
      await model.move(from: [2], to: 0)
    }

    XCTAssertEqual(try positions(of: [workStepID]), before)
  }

  /// The all screen never shows the fulfilled steps, so reordering there must not drag them
  /// along — they keep the positions they had.
  func testMovingOnTheAllScreenOnlyTouchesTheRowsItShows() async throws {
    let fulfilledPositionBefore = try positions(of: [thirdStepID])

    try await withModel(.all) { model in
      await model.move(from: [2], to: 0)

      XCTAssertEqual(
        model.requestRows.map(\.request.title),
        ["Work step", "First step", "Second step"]
      )
    }

    XCTAssertEqual(try positions(of: [thirdStepID]), fulfilledPositionBefore)
  }

  // MARK: - Helpers

  /// Runs the body against a model wired to this test's database, with the rows already loaded
  /// rather than racing the query `init` kicks off. Each run gets its own storage, so the
  /// remembered toggle of one test never reaches the next.
  private func withModel(
    _ detailType: RequestsDetailModel.DetailType,
    _ body: @MainActor (RequestsDetailModel) async throws -> Void
  ) async throws {
    try await withDependencies {
      $0.defaultDatabase = database
      $0.defaultAppStorage = ephemeralAppStorage()
    } operation: {
      let model = RequestsDetailModel(detailType: detailType)
      await model.updateQuery()
      try await body(model)
    }
  }

  private func ephemeralAppStorage() -> UserDefaults {
    UserDefaults(suiteName: "RequestsDetailModelTests-\(UUID().uuidString)")!
  }

  private func positions(of ids: [Request.ID]) throws -> [Int] {
    try ids.map { id in
      try database.read { db in
        try Request.find(id).select(\.position).fetchOne(db)
      } ?? -1
    }
  }
}
