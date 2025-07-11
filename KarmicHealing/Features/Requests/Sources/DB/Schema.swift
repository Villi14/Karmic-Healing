import Dependencies
import Foundation
import IssueReporting
import OSLog
import SharingGRDB
import SwiftUI

@Table
struct RequestsList: Hashable, Identifiable {
  let id: UUID
  @Column(as: Color.HexRepresentation.self)
  var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
  var position = 0
  var title = ""
}

extension RequestsList.Draft: Identifiable {}

@Table
struct Request: Codable, Equatable, Identifiable {
  let id: UUID
  var dueDate: Date?
  var isCompleted = false
  var isFlagged = false
  var notes = ""
  var position = 0
  var priority: Priority?
  var requestsListID: RequestsList.ID
  var title = ""
}

extension Request.Draft: Identifiable {}

enum Priority: Int, Codable, QueryBindable {
  case low = 1
  case medium
  case high
}

extension Request {
  static let incomplete = Self.where { !$0.isCompleted }
  static func searching(_ text: String) -> Where<Request> {
    Self.where {
      $0.title.collate(.nocase).contains(text)
        || $0.notes.collate(.nocase).contains(text)
    }
  }
}

extension Request.TableColumns {
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

public func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context
  let database: any DatabaseWriter
  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
    #if DEBUG
      db.trace(options: .profile) {
        if context == .live {
          logger.debug("\($0.expandedDescription)")
        } else {
          print("\($0.expandedDescription)")
        }
      }
    #endif
  }

  if context == .preview {
    database = try DatabaseQueue(configuration: configuration)
  } else {
    let path =
      context == .live
      ? URL.documentsDirectory.appending(component: "db.sqlite").path()
      : URL.temporaryDirectory.appending(component: "\(UUID().uuidString)-db.sqlite").path()
    logger.info("open \(path)")
    database = try DatabasePool(path: path, configuration: configuration)
  }

  var migrator = DatabaseMigrator()
  #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
  #endif
  migrator.registerMigration("Create initial tables") { db in
    try #sql(
      """
      CREATE TABLE "requestsLists" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "color" INTEGER NOT NULL DEFAULT \(raw: 0x4a99_ef00),
        "position" INTEGER NOT NULL DEFAULT 0,
        "title" TEXT NOT NULL
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "requests" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "dueDate" TEXT,
        "isCompleted" INTEGER NOT NULL DEFAULT 0,
        "isFlagged" INTEGER NOT NULL DEFAULT 0,
        "notes" TEXT,
        "position" INTEGER NOT NULL DEFAULT 0,
        "priority" INTEGER,
        "requestsListID" TEXT NOT NULL,
        "title" TEXT NOT NULL,

        FOREIGN KEY("requestsListID") REFERENCES "requestsLists"("id") ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TABLE "tags" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "title" TEXT NOT NULL COLLATE NOCASE
      ) STRICT
      """
    )
    .execute(db)
    
    try #sql(
      """
      CREATE TABLE "requestsTags" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "requestID" TEXT NOT NULL,
        "tagID" TEXT NOT NULL,

        FOREIGN KEY("requestID") REFERENCES "requests"("id") ON DELETE CASCADE,
        FOREIGN KEY("tagID") REFERENCES "tags"("id") ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)
  }

  try migrator.migrate(database)

  if context == .preview {
    try database.write { db in
      try db.seedSampleData()
    }
  }

  try database.write { db in
    try #sql(
      """
      CREATE TEMPORARY TRIGGER "default_position_requests_lists" 
      AFTER INSERT ON "requestsLists"
      FOR EACH ROW BEGIN
        UPDATE "requestsLists"
        SET "position" = (SELECT max("position") + 1 FROM "requestsLists")
        WHERE "id" = NEW."id";
      END
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TEMPORARY TRIGGER "default_position_requests" 
      AFTER INSERT ON "requests"
      FOR EACH ROW BEGIN
        UPDATE "requests"
        SET "position" = (SELECT max("position") + 1 FROM "requests")
        WHERE "id" = NEW."id";
      END
      """
    )
    .execute(db)
    try #sql(
      """
      CREATE TEMPORARY TRIGGER "non_empty_requests_lists" 
      AFTER DELETE ON "requestsLists"
      FOR EACH ROW BEGIN
        INSERT INTO "requestsLists"
        ("title", "color")
        SELECT 'Personal', \(raw: 0x4a99ef)
        WHERE (SELECT count(*) FROM "requestsLists") = 0;
      END
      """
    )
    .execute(db)
  }

  return database
}

private let logger = Logger(subsystem: "Requests", category: "Database")

#if DEBUG
  extension Database {
    func seedSampleData() throws {
      let requestsListIDs = (0...2).map { _ in UUID() }
      let requestIDs = (0...10).map { _ in UUID() }

      try seed {
        RequestsList(
          id: requestsListIDs[0],
          color: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255),
          title: "Personal"
        )

        RequestsList(
          id: requestsListIDs[1],
          color: Color(red: 0xed / 255, green: 0x89 / 255, blue: 0x35 / 255),
          title: "Family"
        )

        RequestsList(
          id: requestsListIDs[2],
          color: Color(red: 0xb2 / 255, green: 0x5d / 255, blue: 0xd3 / 255),
          title: "Business"
        )

        Request(
          id: requestIDs[0],
          notes: "Milk\nEggs\nApples\nOatmeal\nSpinach",
          requestsListID: requestsListIDs[0],
          title: "Groceries"
        )

        Request(
          id: requestIDs[1],
          dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
          isFlagged: true,
          requestsListID: requestsListIDs[0],
          title: "Haircut"
        )

        Request(
          id: requestIDs[2],
          dueDate: Date(),
          notes: "Ask about diet",
          priority: .high,
          requestsListID: requestsListIDs[0],
          title: "Doctor appointment"
        )

        Request(
          id: requestIDs[3],
          dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 190),
          isCompleted: true,
          requestsListID: requestsListIDs[0],
          title: "Take a walk"
        )

        Request(
          id: requestIDs[4],
          dueDate: Date(),
          requestsListID: requestsListIDs[0],
          title: "Buy concert tickets"
        )

        Request(
          id: requestIDs[5],
          dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
          isFlagged: true,
          priority: .high,
          requestsListID: requestsListIDs[1],
          title: "Pick up kids from school"
        )

        Request(
          id: requestIDs[6],
          dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .low,
          requestsListID: requestsListIDs[1],
          title: "Get laundry"
        )

        Request(
          id: requestIDs[7],
          dueDate: Date().addingTimeInterval(60 * 60 * 24 * 4),
          isCompleted: false,
          priority: .high,
          requestsListID: requestsListIDs[1],
          title: "Take out trash"
        )

        Request(
          id: requestIDs[8],
          dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
          notes: """
            Status of tax return
            Expenses for next year
            Changing payroll company
            """,
          requestsListID: requestsListIDs[2],
          title: "Call accountant"
        )

        Request(
          id: requestIDs[9],
          dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .medium,
          requestsListID: requestsListIDs[2],
          title: "Send weekly emails"
        )

        Request(
          id: requestIDs[10],
          dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
          isCompleted: false,
          requestsListID: requestsListIDs[2],
          title: "Prepare for WWDC"
        )
      }
    }
  }
#endif
