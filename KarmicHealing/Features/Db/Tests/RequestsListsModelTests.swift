//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import SQLiteData
import XCTest
@testable import Db

@MainActor
final class RequestsListsModelTests: XCTestCase {
  private var database: (any DatabaseWriter)!
  private let familyID = UUID()
  private let workID = UUID()
  private let healthID = UUID()

  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try appDatabase()

    try database.write { db in
      try RequestsList.insert {
        RequestsList(id: familyID, title: "Family")
        RequestsList(id: workID, title: "Work")
        RequestsList(id: healthID, title: "Health")
      }
      .execute(db)
    }
  }

  override func tearDown() {
    database = nil
    super.tearDown()
  }

  func testTheScreenListsEveryRequestInItsOwnOrder() async throws {
    try await withModel { model in
      XCTAssertEqual(model.requestsLists.map(\.title), ["Family", "Work", "Health"])
      XCTAssertEqual(model.requestsListsArray.map(\.requestsList.title), model.requestsLists.map(\.title))
    }
  }

  // MARK: - Reordering

  func testMovingARequestUpRenumbersTheWholeList() async throws {
    try await withModel { model in
      model.move(from: [2], to: 0)
      try await model.$requestsLists.load()

      XCTAssertEqual(model.requestsLists.map(\.title), ["Health", "Family", "Work"])
    }

    XCTAssertEqual(try positions(of: [healthID, familyID, workID]), [0, 1, 2])
  }

  /// `move(fromOffsets:toOffset:)` reads the destination in the list as it stands before the
  /// row leaves it, so dropping below the last row means an index one past the end.
  func testMovingARequestDownLandsItWhereItWasDropped() async throws {
    try await withModel { model in
      model.move(from: [0], to: 3)
      try await model.$requestsLists.load()

      XCTAssertEqual(model.requestsLists.map(\.title), ["Work", "Health", "Family"])
    }
  }

  func testMovingLeavesTheSubrequestsOfEveryRequestAlone() async throws {
    let stepID = UUID()
    try await database.write { [familyID] db in
      try Request.insert {
        Request.Draft(id: stepID, requestsListID: familyID, title: "First step")
      }
      .execute(db)
    }

    try await withModel { model in
      model.move(from: [2], to: 0)
    }

    let step = try await database.read { try Request.find(stepID).fetchOne($0) }
    XCTAssertEqual(step?.requestsListID, familyID)
    XCTAssertEqual(step?.title, "First step")
  }

  // MARK: - Where the taps lead

  func testTappingARequestOpensItsOwnScreen() async throws {
    try await withModel { model in
      let family = try XCTUnwrap(model.requestsLists.first { $0.id == self.familyID })

      model.requestsListTapped(requestsList: family)

      guard case .detail(let detail) = model.destination else {
        return XCTFail("Expected the request's screen")
      }
      XCTAssertEqual(detail.detailType, .requestsList(family))
    }
  }

  func testAddingARequestOpensAnEmptyForm() async throws {
    try await withModel { model in
      model.addListButtonTapped()

      guard case .requestsListForm(let draft) = model.destination else {
        return XCTFail("Expected the request form")
      }
      XCTAssertNil(draft.id, "A new request must not carry an existing one's identity")
      XCTAssertEqual(draft.title, "")
    }
  }

  func testEditingARequestOpensTheFormOnIt() async throws {
    try await withModel { model in
      let family = try XCTUnwrap(model.requestsLists.first { $0.id == self.familyID })

      model.listDetailsButtonTapped(requestsList: family)

      guard case .requestsListForm(let draft) = model.destination else {
        return XCTFail("Expected the request form")
      }
      XCTAssertEqual(draft.id, familyID)
      XCTAssertEqual(draft.title, "Family")
    }
  }

  func testHelpIsPresentedOnDemand() async throws {
    try await withModel { model in
      XCTAssertFalse(model.isHelpPresented)

      model.helpButtonTapped()

      XCTAssertTrue(model.isHelpPresented)
      XCTAssertNil(model.destination, "Help is a sheet, not a screen on the stack")
    }
  }

#if DEBUG
  func testSeedingFillsTheDatabase() async throws {
    try await withModel { model in
      model.seedDatabaseButtonTapped()
      try await model.$requestsLists.load()

      XCTAssertEqual(
        model.requestsLists.count, 6,
        "Seeding adds its three sample requests to what was already there"
      )
      let subrequestCount = try await self.database.read { try Request.all.fetchCount($0) }
      XCTAssertTrue(subrequestCount > 0, "The seeded requests came without their subrequests")
    }
  }
#endif

  // MARK: - Helpers

  /// Runs the body against a model wired to this test's database, with the lists already
  /// loaded rather than racing the query the model starts on its own.
  private func withModel(
    _ body: @MainActor (RequestsListsModel) async throws -> Void
  ) async throws {
    try await withDependencies {
      $0.defaultDatabase = database
    } operation: {
      let model = RequestsListsModel()
      try await model.$requestsLists.load()
      try await body(model)
    }
  }

  private func positions(of ids: [RequestsList.ID]) throws -> [Int] {
    try ids.map { id in
      try database.read { db in
        try RequestsList.find(id).select(\.position).fetchOne(db)
      } ?? -1
    }
  }
}
