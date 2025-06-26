// Karmic Healing 2025

import SharingGRDB
import SwiftUI

struct NoteRow: View {
  let color: Color
  let isPastDue: Bool
  let notes: String
  let note: Note
  let notesList: NotesList

  @State var editNote: Note.Draft?

  @Dependency(\.defaultDatabase) private var database

  init(
    color: Color,
    isPastDue: Bool,
    notes: String,
    note: Note,
    notesList: NotesList
  ) {
    self.color = color
    self.isPastDue = isPastDue
    self.notes = notes
    self.note = note
    self.notesList = notesList
  }

  var body: some View {
    HStack {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading) {
          title(for: note)

          if !notes.isEmpty {
            Text(notes)
              .font(.subheadline)
              .foregroundStyle(.gray)
              .lineLimit(2)
          }
          subtitleText
        }
      }
    }
    .buttonStyle(.borderless)
    .swipeActions {
      Button("Delete", role: .destructive) {
        withErrorReporting {
          try database.write { db in
            try Note.delete(note).execute(db)
          }
        }
      }
      Button(note.isFlagged ? "Unflag" : "Flag") {
        withErrorReporting {
          try database.write { db in
            try Note
              .find(note.id)
              .update { $0.isFlagged.toggle() }
              .execute(db)
          }
        }
      }
      .tint(.orange)
      Button("Details") {
        editNote = Note.Draft(note)
      }
    }
    .sheet(item: $editNote) { note in
      NavigationStack {
        NoteFormView(note: note, notesList: notesList)
          .navigationTitle("Details")
      }
    }
  }

  private var dueText: Text {
    if let date = note.dueDate {
      Text(date.formatted(date: .numeric, time: .shortened))
        .foregroundStyle(isPastDue ? .red : .gray)
    } else {
      Text("")
    }
  }

  private var subtitleText: Text {

    return
      (dueText
      .foregroundStyle(.gray)
      .bold())
      .font(.callout)
  }

  private func title(for note: Note) -> some View {
    return HStack(alignment: .firstTextBaseline) {
      Text(note.title)
        .foregroundStyle(.primary)
    }
    .font(.title3)
  }
}

struct NoteRowPreview: PreviewProvider {
  static var previews: some View {
    var note: Note!
    var notesList: NotesList!
    let _ = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      try $0.defaultDatabase.read { db in
        note = try Note.all.fetchOne(db)
        notesList = try NotesList.all.fetchOne(db)!
      }
    }

    NavigationStack {
      List {
        NoteRow(
          color: notesList.color,
          isPastDue: false,
          notes: note.notes.replacingOccurrences(of: "\n", with: " "),
          note: note,
          notesList: notesList
        )
      }
    }
  }
}

