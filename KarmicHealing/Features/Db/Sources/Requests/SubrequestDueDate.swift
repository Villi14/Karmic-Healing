//
// Karmic Healing 2025
//

import Common
import Foundation
import GRDB
import OSLog
import SQLiteData

// MARK: - The Date a Subrequest Borrows

extension RequestsList {
  /// Copies a request's date onto every one of its subrequests.
  ///
  /// A subrequest is a step towards its request, so it is due when the request is. The date is
  /// stored rather than derived — search and ordering read it straight off the row — but it is
  /// never shown on a subrequest, and never edited there. Call this whenever a request's date
  /// changes, and whenever a subrequest is written.
  static func inheritDueDate(of id: RequestsList.ID, in db: Database) throws {
    guard let request = try RequestsList.find(id).fetchOne(db) else { return }

    try Request
      .where { $0.requestsListID.eq(id) }
      .update { $0.dueDate = request.dueDate }
      .execute(db)

    Log.database.debug("Subrequests of \(id, privacy: .public) took their request's date")
  }
}
