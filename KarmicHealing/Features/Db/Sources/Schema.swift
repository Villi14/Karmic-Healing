//
// Karmic Healing 2025
//

import Common
import Dependencies
import Foundation
import IssueReporting
import OSLog
import SQLiteData
import SwiftUI

/// A request the user brings to their practice.
///
/// It stands on its own, or it is broken down into `Request` subrequests that pave the way to it.
@Table
struct RequestsList: Hashable, Identifiable {
  let id: UUID
  /// A new request starts in the colour its screen already wears, so the picker offers a
  /// change of tone rather than a stranger's blue.
  @Column(as: Color.HexRepresentation.self)
  var color = Spectrum.sacral.color
  var position = 0
  var title = ""
  var description = ""
  var isCompleted = false
  var priority: Priority?
  var dueDate: Date?
  var notes = ""
}

extension RequestsList.Draft: Identifiable {}

extension RequestsList {
  static let incomplete = Self.where { !$0.isCompleted }

  /// Matches the request's own words, whatever the case they are written in.
  ///
  /// `LIKE` and the `NOCASE` collation fold ASCII only, so they miss every Ukrainian and
  /// Russian word typed in a different case than it was saved. `swiftLowercaseString` is
  /// GRDB's own function backed by Swift's `lowercased()`, which knows the whole alphabet.
  static func searching(_ text: String) -> Where<RequestsList> {
    let pattern = "%\(text.lowercased())%"
    return Self.where {
      #sql("swiftLowercaseString(\($0.title)) LIKE \(pattern)")
      || #sql("swiftLowercaseString(\($0.description)) LIKE \(pattern)")
      || #sql("swiftLowercaseString(\($0.notes)) LIKE \(pattern)")
    }
  }
}

extension RequestsList.TableColumns {
  var isPastDue: some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    return !isCompleted && #sql("coalesce(date(\(dueDate)) < date(\(now)), 0)")
  }

  var isToday: some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    return !isCompleted && #sql("coalesce(date(\(dueDate)) = date(\(now)), 0)")
  }

  var isScheduled: some QueryExpression<Bool> {
    !isCompleted && dueDate.isNot(nil)
  }

  var inlineNotes: some QueryExpression<String> {
    notes.replace("\n", " ")
  }
}

/// A subrequest — a step that has to be fulfilled before its `RequestsList` request can be.
///
/// It has no priority of its own, and no date of its own either: `dueDate` is a copy of the
/// date of the request it serves, kept in step by `inheritDueDate` and never shown or edited
/// on the subrequest itself.
@Table
struct Request: Codable, Equatable, Identifiable {
  let id: UUID
  var dueDate: Date?
  var isCompleted = false
  var notes = ""
  var position = 0
  var requestsListID: RequestsList.ID
  var title = ""
}

extension Request.Draft: Identifiable {}

extension Request {
  static let incomplete = Self.where { !$0.isCompleted }

  /// Matches the subrequest's words in any case — see `RequestsList.searching`.
  static func searching(_ text: String) -> Where<Request> {
    let pattern = "%\(text.lowercased())%"
    return Self.where {
      #sql("swiftLowercaseString(\($0.title)) LIKE \(pattern)")
      || #sql("swiftLowercaseString(\($0.notes)) LIKE \(pattern)")
    }
  }
}

extension Request.TableColumns {
  var inlineNotes: some QueryExpression<String> {
    notes.replace("\n", " ")
  }
}

@Table
struct Reminder: Codable, Equatable, Identifiable {
  let id: UUID
  var dueDate: Date?
  var isCompleted = false
  var isFlagged = false
  var notes = ""
  var position = 0
  var priority: Priority?
  var remindersListID: RemindersList.ID
  var title = ""
}

extension Reminder.Draft: Identifiable {}

@Table
struct RemindersList: Hashable, Identifiable {
  let id: UUID
  /// A new topic starts in the reminders' own colour — see `RequestsList.color`.
  @Column(as: Color.HexRepresentation.self)
  var color = Spectrum.solar.color
  var position = 0
  var title = ""
}

extension RemindersList.Draft: Identifiable {}

extension Reminder {
  static let incomplete = Self.where { !$0.isCompleted }

  /// Matches the reminder's words in any case — see `RequestsList.searching`.
  static func searching(_ text: String) -> Where<Reminder> {
    let pattern = "%\(text.lowercased())%"
    return Self.where {
      #sql("swiftLowercaseString(\($0.title)) LIKE \(pattern)")
      || #sql("swiftLowercaseString(\($0.notes)) LIKE \(pattern)")
    }
  }
}

extension Reminder.TableColumns {
  var isPastDue: some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    return !isCompleted && #sql("coalesce(date(\(dueDate)) < date(\(now)), 0)")
  }

  var isToday: some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    return !isCompleted && #sql("coalesce(date(\(dueDate)) = date(\(now)), 0)")
  }

  var isScheduled: some QueryExpression<Bool> {
    !isCompleted && dueDate.isNot(nil)
  }

  var inlineNotes: some QueryExpression<String> {
    notes.replace("\n", " ")
  }
}

enum Priority: Int, Codable, QueryBindable {
  case low = 1
  case medium
  case high
}
