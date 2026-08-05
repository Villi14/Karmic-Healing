//
// Karmic Healing 2025
//

import Common
import Foundation
import GRDB
import OSLog
import SQLiteData

/// How many subrequests a request has, and how many of them are already fulfilled.
///
/// A request without subrequests counts as fully covered — `allCompleted` is `true` —
/// so it can be fulfilled at any moment.
struct SubrequestProgress: Equatable {
  var total = 0
  var completed = 0

  var hasSubrequests: Bool { total > 0 }
  var allCompleted: Bool { completed == total }
}

// MARK: - Request Completion Rules

extension RequestsList {
  /// Counts the subrequests belonging to the given request.
  static func subrequestProgress(of id: RequestsList.ID, in db: Database) throws -> SubrequestProgress {
    let total = try Request.where { $0.requestsListID.eq(id) }.fetchCount(db)
    let completed = try Request.where { $0.requestsListID.eq(id) && $0.isCompleted }.fetchCount(db)
    return SubrequestProgress(total: total, completed: completed)
  }

  /// Whether the user may flip this request's radio button right now.
  ///
  /// Fulfilling a request asks for every subrequest to be fulfilled first; a request that is
  /// already fulfilled can always be reopened.
  static func canToggleCompletion(_ request: RequestsList, progress: SubrequestProgress) -> Bool {
    request.isCompleted || progress.allCompleted
  }

  /// Flips the request's completion when the rules allow it, and returns the resulting state.
  ///
  /// Nothing here happens on its own: a request is only ever fulfilled by this call, never by
  /// its subrequests reaching the finish line.
  @discardableResult
  static func toggleCompletion(of id: RequestsList.ID, in db: Database) throws -> Bool {
    guard let request = try RequestsList.find(id).fetchOne(db) else { return false }

    let progress = try subrequestProgress(of: id, in: db)
    guard canToggleCompletion(request, progress: progress) else {
      Log.database.debug("Request \(id, privacy: .public) still waits for its subrequests")
      return request.isCompleted
    }

    let isCompleted = !request.isCompleted
    try RequestsList
      .find(id)
      .update { $0.isCompleted = isCompleted }
      .execute(db)

    Log.database.debug("Request \(id, privacy: .public) isCompleted -> \(isCompleted, privacy: .public)")
    return isCompleted
  }

  /// Reopens a fulfilled request as soon as one of its subrequests is unfinished.
  ///
  /// Call it after any change beneath a request — a subrequest toggled, added or deleted — so a
  /// request never stays fulfilled while something under it is still open.
  static func syncCompletion(of id: RequestsList.ID, in db: Database) throws {
    let progress = try subrequestProgress(of: id, in: db)
    guard !progress.allCompleted else { return }

    try RequestsList
      .where { $0.id.eq(id) && $0.isCompleted }
      .update { $0.isCompleted = false }
      .execute(db)
  }
}
