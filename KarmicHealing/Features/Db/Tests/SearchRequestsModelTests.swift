//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import SQLiteData
import XCTest
@testable import Db

@MainActor
final class SearchRequestsModelTests: XCTestCase {
  private var database: (any DatabaseWriter)!
  private let requestID = UUID()

  override func setUpWithError() throws {
    try super.setUpWithError()
    database = try appDatabase()

    try database.write { [requestID] db in
      try RequestsList.insert {
        RequestsList(id: requestID, title: "Family", description: "Peace at home")
      }
      .execute(db)
      try Request.insert {
        Request.Draft(notes: "Ask for guidance", requestsListID: requestID, title: "Healing step")
        Request.Draft(isCompleted: true, requestsListID: requestID, title: "Family gratitude")
      }
      .execute(db)
    }
  }

  override func tearDown() {
    database = nil
    super.tearDown()
  }

  func testSearchFindsRequestsByTheirOwnTitle() async throws {
    try await search(for: "family") { model in
      XCTAssertEqual(model.requests.map(\.title), ["Family"])
    }
  }

  func testSearchFindsRequestsByTheirDescription() async throws {
    try await search(for: "peace") { model in
      XCTAssertEqual(model.requests.map(\.title), ["Family"])
    }
  }

  func testSearchFindsSubrequestsByTitleAndNotes() async throws {
    try await search(for: "healing") { model in
      XCTAssertEqual(model.subrequests.map(\.request.title), ["Healing step"])
    }
    try await search(for: "guidance") { model in
      XCTAssertEqual(model.subrequests.map(\.request.title), ["Healing step"])
    }
  }

  func testSearchCarriesTheRequestEachSubrequestBelongsTo() async throws {
    try await search(for: "healing") { model in
      XCTAssertEqual(model.subrequests.first?.requestsList.title, "Family")
    }
  }

  func testSearchReachesBothLevelsAtOnce() async throws {
    try await search(for: "family") { model in
      XCTAssertEqual(model.requests.map(\.title), ["Family"])
      XCTAssertTrue(model.subrequests.isEmpty, "The matching subrequest is fulfilled, so it stays hidden")
      XCTAssertTrue(model.hasResults)
    }
  }

  func testFulfilledResultsStayHiddenUntilAskedFor() async throws {
    try await search(for: "family") { model in
      XCTAssertTrue(model.subrequests.isEmpty)

      await model.showCompletedButtonTapped()

      XCTAssertEqual(model.subrequests.map(\.request.title), ["Family gratitude"])
    }
  }

  /// A fulfilled request is hidden the same way a fulfilled subrequest is, so the tally has to
  /// count it — otherwise the only door back to it never appears.
  func testFulfilledRequestsAreCountedAndCanBeShown() async throws {
    try await database.write { db in
      try RequestsList.insert {
        RequestsList(id: UUID(), title: "Fulfilled family wish", isCompleted: true)
      }
      .execute(db)
    }

    try await search(for: "fulfilled") { model in
      XCTAssertTrue(model.requests.isEmpty)
      XCTAssertEqual(model.completedCount, 1, "The fulfilled request is not counted")

      await model.showCompletedButtonTapped()

      XCTAssertEqual(model.requests.map(\.title), ["Fulfilled family wish"])
    }
  }

  func testClearingFulfilledAlsoClearsFulfilledRequests() async throws {
    try await database.write { db in
      try RequestsList.insert {
        RequestsList(id: UUID(), title: "Fulfilled family wish", isCompleted: true)
      }
      .execute(db)
    }

    try await search(for: "fulfilled") { model in
      model.deleteCompletedRequests()
      await model.updateQuery()

      XCTAssertEqual(model.completedCount, 0)
      XCTAssertFalse(model.hasResults)
    }
  }

  func testSearchWithoutMatchesReportsNoResults() async throws {
    try await search(for: "nonexistent") { model in
      XCTAssertFalse(model.hasResults)
    }
  }

  func testClearingFulfilledSubrequestsLeavesTheOpenOnes() async throws {
    try await search(for: "") { model in
      XCTAssertEqual(model.completedCount, 1)

      model.deleteCompletedRequests()
      await model.updateQuery()

      XCTAssertEqual(model.completedCount, 0)
      XCTAssertEqual(model.subrequests.map(\.request.title), ["Healing step"])
    }
  }

  /// The screen never calls `updateQuery` itself — typing is the only trigger it has.
  func testTypingAloneLoadsTheResults() async throws {
    try await withDependencies {
      $0.defaultDatabase = database
    } operation: {
      let model = SearchRequestsModel()
      model.searchText = "family"

      try await Task.sleep(for: .milliseconds(500))

      XCTAssertEqual(model.requests.map(\.title), ["Family"])
    }
  }

  /// And on the screen the model is reached through the one that owns it.
  func testTypingThroughTheOwningModelLoadsTheResults() async throws {
    try await withDependencies {
      $0.defaultDatabase = database
    } operation: {
      let listsModel = RequestsListsModel()
      listsModel.searchRequestsModel.searchText = "family"

      try await Task.sleep(for: .milliseconds(500))

      XCTAssertEqual(listsModel.searchRequestsModel.requests.map(\.title), ["Family"])
    }
  }

  /// The screen switches to its results the moment the field has text, so the field itself
  /// has to be observable — otherwise the list below simply never redraws.
  func testTypingNotifiesObservers() {
    withDependencies {
      $0.defaultDatabase = database
    } operation: {
      let model = SearchRequestsModel()
      var observedChange = false

      withObservationTracking {
        _ = model.searchText
      } onChange: {
        observedChange = true
      }

      model.searchText = "family"

      XCTAssertTrue(observedChange, "SwiftUI is never told the search text changed")
    }
  }

  /// And when the results arrive, the list has to be told to draw them.
  func testArrivingResultsNotifyObservers() async throws {
    try await withDependencies {
      $0.defaultDatabase = database
    } operation: {
      let model = SearchRequestsModel()
      var observedChange = false

      withObservationTracking {
        _ = model.requests
      } onChange: {
        observedChange = true
      }

      model.searchText = "family"
      try await Task.sleep(for: .milliseconds(500))

      XCTAssertFalse(model.requests.isEmpty, "The results did load")
      XCTAssertTrue(observedChange, "SwiftUI is never told the results arrived")
    }
  }

  // MARK: - Helpers

  /// Types into the search field and waits for both result sets, rather than racing the `Task`
  /// that `searchText` kicks off. The body runs inside the same dependency scope, so anything
  /// it asks of the model still reaches this test's database.
  private func search(
    for text: String,
    _ body: @MainActor (SearchRequestsModel) async throws -> Void
  ) async throws {
    try await withDependencies {
      $0.defaultDatabase = database
    } operation: {
      let model = SearchRequestsModel()
      model.searchText = text
      await model.updateQuery()
      try await body(model)
    }
  }
}
