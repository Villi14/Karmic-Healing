//
// Karmic Healing 2025
//

import Common
import Dependencies
import Foundation
import OSLog
import SQLiteData

public func appDatabase() throws -> any DatabaseWriter {
  @Dependency(\.context) var context
  let database: any DatabaseWriter
  var configuration = Configuration()
  configuration.foreignKeysEnabled = true
  configuration.prepareDatabase { db in
#if DEBUG
    db.trace(options: .profile) {
      Log.database.debug("\($0.expandedDescription, privacy: .public)")
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
    Log.database.debug("Opening database at \(path, privacy: .public)")
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
        "title" TEXT NOT NULL,
        "description" TEXT NOT NULL DEFAULT '',
        "isCompleted" INTEGER NOT NULL DEFAULT 0,
        "priority" INTEGER,
        "dueDate" TEXT,
        "notes" TEXT NOT NULL DEFAULT ''
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
      CREATE TABLE "remindersLists" (
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
      CREATE TABLE "reminders" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "dueDate" TEXT,
        "isCompleted" INTEGER NOT NULL DEFAULT 0,
        "isFlagged" INTEGER NOT NULL DEFAULT 0,
        "notes" TEXT,
        "position" INTEGER NOT NULL DEFAULT 0,
        "priority" INTEGER,
        "remindersListID" TEXT NOT NULL,
        "title" TEXT NOT NULL,
      
        FOREIGN KEY("remindersListID") REFERENCES "remindersLists"("id") ON DELETE CASCADE
      ) STRICT
      """
    )
    .execute(db)
  }

  migrator.registerMigration("Drop the priority of subrequests") { db in
    try #sql(#"ALTER TABLE "requests" DROP COLUMN "priority""#).execute(db)
  }

  try migrator.migrate(database)

#if DEBUG
  if context == .preview {
    try database.write { db in
      try db.seedSampleData()
    }
  }
#endif

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
      CREATE TEMPORARY TRIGGER "default_position_reminders_lists" 
      AFTER INSERT ON "remindersLists"
      FOR EACH ROW BEGIN
        UPDATE "remindersLists"
        SET "position" = (SELECT max("position") + 1 FROM "remindersLists")
        WHERE "id" = NEW."id";
      END
      """
    )
    .execute(db)

    try #sql(
      """
      CREATE TEMPORARY TRIGGER "default_position_reminders" 
      AFTER INSERT ON "reminders"
      FOR EACH ROW BEGIN
        UPDATE "reminders"
        SET "position" = (SELECT max("position") + 1 FROM "reminders")
        WHERE "id" = NEW."id";
      END
      """
    )
    .execute(db)
  }

  return database
}
