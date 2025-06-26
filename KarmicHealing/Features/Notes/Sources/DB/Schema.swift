// Karmic Healing 2025

import Dependencies
import Foundation
import IssueReporting
import OSLog
import SharingGRDB
import SwiftUI
import Common

@Table
struct NotesList: Hashable, Identifiable {
  let id: UUID
  @Column(as: Color.HexRepresentation.self)
  var color = Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
  var position = 0
  var title = ""
}

extension NotesList.Draft: Identifiable {}

@Table
struct Note: Codable, Equatable, Identifiable {
  let id: UUID
  var dueDate: Date?
  var isFlagged = false
  var notes = ""
  var position = 0
  var notesListID: NotesList.ID
  var title = ""
}

extension Note.Draft: Identifiable {}

extension Note {
  static func searching(_ text: String) -> Where<Note> {
    Self.where {
      $0.title.collate(.nocase).contains(text)
      || $0.notes.collate(.nocase).contains(text)
    }
  }
}

extension Note.TableColumns {
  var isPastDue: some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    return #sql("coalesce(date(\(dueDate)) < date(\(now)), 0)")
  }
  var isToday: some QueryExpression<Bool> {
    @Dependency(\.date.now) var now
    return #sql("coalesce(date(\(dueDate)) = date(\(now)), 0)")
  }
  var isScheduled: some QueryExpression<Bool> {
    dueDate.isNot(nil)
  }
  var inlineNotes: some QueryExpression<String> {
    notes.replace("\n", " ")
  }
}

func appDatabase() throws -> any DatabaseWriter {
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
      CREATE TABLE "notesLists" (
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
      CREATE TABLE "notes" (
        "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
        "dueDate" TEXT,
        "isFlagged" INTEGER NOT NULL DEFAULT 0,
        "notes" TEXT,
        "position" INTEGER NOT NULL DEFAULT 0,
        "notesListID" TEXT NOT NULL,
        "title" TEXT NOT NULL,
      
        FOREIGN KEY("notesListID") REFERENCES "notesLists"("id") ON DELETE CASCADE
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
      CREATE TEMPORARY TRIGGER "default_position_notes_lists" 
      AFTER INSERT ON "notesLists"
      FOR EACH ROW BEGIN
        UPDATE "notesLists"
        SET "position" = (SELECT max("position") + 1 FROM "notesLists")
        WHERE "id" = NEW."id";
      END
      """
    )
    .execute(db)
    
    try #sql(
      """
      CREATE TEMPORARY TRIGGER "default_position_notes" 
      AFTER INSERT ON "notes"
      FOR EACH ROW BEGIN
        UPDATE "notes"
        SET "position" = (SELECT max("position") + 1 FROM "notes")
        WHERE "id" = NEW."id";
      END
      """
    )
    .execute(db)
    
    try #sql(
      """
      CREATE TEMPORARY TRIGGER "non_empty_notes_lists" 
      AFTER DELETE ON "notesLists"
      FOR EACH ROW BEGIN
        INSERT INTO "notesLists"
        ("title", "color")
        SELECT 'Personal', \(raw: 0x4a99ef)
        WHERE (SELECT count(*) FROM "notesLists") = 0;
      END
      """
    )
    .execute(db)
  }
  
  return database
}

private let logger = Logger(subsystem: "Notes", category: "Database")

#if DEBUG
extension Database {
  func seedSampleData() throws {
    let noteListIDs = (0...2).map { _ in UUID() }
    let noteIDs = (0...10).map { _ in UUID() }
    
    try seed {
      NotesList(
        id: noteListIDs[0],
        color: Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255),
        title: "Personal"
      )
      
      NotesList(
        id: noteListIDs[1],
        color: Color(red: 0xed / 255, green: 0x89 / 255, blue: 0x35 / 255),
        title: "Family"
      )
      
      NotesList(
        id: noteListIDs[2],
        color: Color(red: 0xb2 / 255, green: 0x5d / 255, blue: 0xd3 / 255),
        title: "Business"
      )
      
      Note(
        id: noteIDs[0],
        notes: "Milk\nEggs\nApples\nOatmeal\nSpinach",
        notesListID: noteListIDs[0],
        title: "Groceries"
      )
      
      Note(
        id: noteIDs[1],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
        isFlagged: true,
        notesListID: noteListIDs[0],
        title: "Haircut"
      )
      
      Note(
        id: noteIDs[2],
        dueDate: Date(),
        notes: "Ask about diet",
        notesListID: noteListIDs[0],
        title: "Doctor appointment"
      )
      
      Note(
        id: noteIDs[3],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 190),
        notesListID: noteListIDs[0],
        title: "Take a walk"
      )
      
      Note(
        id: noteIDs[4],
        dueDate: Date(),
        notesListID: noteListIDs[0],
        title: "Buy concert tickets"
      )
      
      Note(
        id: noteIDs[5],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        isFlagged: true,
        notesListID: noteListIDs[1],
        title: "Pick up kids from school"
      )
      
      Note(
        id: noteIDs[6],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
        notesListID: noteListIDs[1],
        title: "Get laundry"
      )
      
      Note(
        id: noteIDs[7],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 4),
        notesListID: noteListIDs[1],
        title: "Take out trash"
      )
      
      Note(
        id: noteIDs[8],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        notes: """
            Status of tax return
            Expenses for next year
            Changing payroll company
            """,
        notesListID: noteListIDs[2],
        title: "Call accountant"
      )
      
      Note(
        id: noteIDs[9],
        dueDate: Date().addingTimeInterval(-60 * 60 * 24 * 2),
        notesListID: noteListIDs[2],
        title: "Send weekly emails"
      )
      
      Note(
        id: noteIDs[10],
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 2),
        notesListID: noteListIDs[2],
        title: "Prepare for WWDC"
      )
    }
  }
}
#endif
