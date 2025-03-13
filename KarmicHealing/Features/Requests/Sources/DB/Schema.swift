// Karmic Healing 2025

import Foundation
import OSLog
import SharingGRDB

@Table
struct RequestsList: Equatable, Identifiable {
  let id: Int
  var color = 0x4a99ef_ff
  var title = ""
}
extension RequestsList.Draft: Identifiable {}

@Table
struct Tag: Identifiable {
  let id: Int
  var title = ""
}

@Table
struct Request: Identifiable {
  let id: Int
  @Column(as: Date.ISO8601Representation?.self)
  var dueDate: Date?
  var isCompleted = false
  var isFlagged = false
  var notes = ""
  var priority: Priority?
  var requestsListID: RequestsList.ID
  var title = ""

  enum Priority: Int, QueryBindable {
    case low = 1
    case medium
    case high
  }
}
extension Request.Draft: Identifiable {}

@Table
struct requestTag {
  let requestID: Request.ID
  let tagID: Tag.ID
}

func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context

  let database: any DatabaseWriter

  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
    #if DEBUG
      db.trace(options: .profile) {
        if context == .preview {
          print($0.expandedDescription)
        } else {
          logger.debug("\($0.expandedDescription)")
        }
      }
    #endif
  }

  switch context {
  case .live:
    let path = URL.documentsDirectory.appending(component: "db.sqlite").path()
    logger.info("open \(path)")
    database = try DatabasePool(path: path, configuration: configuration)
  case .preview, .test:
    database = try DatabaseQueue(configuration: configuration)
  }

  var migrator = DatabaseMigrator()
  #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
  #endif
  migrator.registerMigration("Create tables") { db in
    try #sql(
      """
      CREATE TABLE "requestsLists" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "color" INTEGER NOT NULL DEFAULT \(raw: 0x4a99ef_ff),
        "title" TEXT NOT NULL DEFAULT ''
      ) STRICT
      """
    )
    .execute(db)
    try #sql(
      """
      CREATE TABLE "tags" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "title" TEXT NOT NULL DEFAULT ''
      ) STRICT
      """
    )
    .execute(db)
    try #sql(
      """
      CREATE TABLE "requests" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "dueDate" TEXT,
        "isCompleted" INTEGER NOT NULL DEFAULT 0,
        "isFlagged" INTEGER NOT NULL DEFAULT 0,
        "notes" TEXT NOT NULL DEFAULT '',
        "priority" INTEGER,
        "requestsListID" INTEGER NOT NULL REFERENCES "requestsLists"("id") ON DELETE CASCADE,
        "title" TEXT NOT NULL DEFAULT ''
      ) STRICT
      """
    )
    .execute(db)
    try #sql(
      """
      CREATE TABLE "requestTags" (
        "requestID" INTEGER NOT NULL REFERENCES "requests"("id") ON DELETE CASCADE,
        "tagID" INTEGER NOT NULL REFERENCES "tags"("id") ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)
  }
  #if DEBUG
    migrator.registerMigration("Seed database") { db in
      @Dependency(\.date.now) var now
      try db.seed {
        RequestsList(id: 1, color: 0x4a99ef_ff, title: "Personal")
        RequestsList(id: 2, color: 0xef7e4a_ff, title: "Family")
        RequestsList(id: 3, color: 0x7ee04a_ff, title: "Business")

        Request(
          id: 1,
          notes: "Milk\nEggs\nApples\nOatmeal\nSpinach",
          requestsListID: 1,
          title: "Groceries"
        )
        Request(
          id: 2,
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isFlagged: true,
          requestsListID: 1,
          title: "Haircut"
        )
        Request(
          id: 3,
          dueDate: now,
          notes: "Ask about diet",
          priority: .high,
          requestsListID: 1,
          title: "Doctor appointment"
        )
        Request(
          id: 4,
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 190),
          isCompleted: true,
          requestsListID: 1,
          title: "Take a walk"
        )
        Request(
          id: 5,
          dueDate: now,
          requestsListID: 1,
          title: "Buy concert tickets"
        )
        Request(
          id: 6,
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
          isFlagged: true,
          priority: .high,
          requestsListID: 2,
          title: "Pick up kids from school"
        )
        Request(
          id: 7,
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .low,
          requestsListID: 2,
          title: "Get laundry"
        )
        Request(
          id: 8,
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 4),
          isCompleted: false,
          priority: .high,
          requestsListID: 2,
          title: "Take out trash"
        )
        Request(
          id: 9,
          dueDate: now.addingTimeInterval(60 * 60 * 24 * 2),
          notes: """
            Status of tax return
            Expenses for next year
            Changing payroll company
            """,
          requestsListID: 3,
          title: "Call accountant"
        )
        Request(
          id: 10,
          dueDate: now.addingTimeInterval(-60 * 60 * 24 * 2),
          isCompleted: true,
          priority: .medium,
          requestsListID: 3,
          title: "Send weekly emails"
        )
      }
    }
  #endif

  try migrator.migrate(database)

  return database
}

private let logger = Logger(subsystem: "Requests", category: "Database")


