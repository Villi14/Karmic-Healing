// Karmic Healing 2025

import IssueReporting
import SharingGRDB
import SwiftUI

@MainActor
@Observable
class SearchNotesModel {
  var searchText = "" {
    didSet {
      Task { await updateQuery() }
    }
  }

  @ObservationIgnored @FetchAll var notes: [Row]

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  func deleteCompletedNotes(monthsAgo: Int? = nil) {
    withErrorReporting {
      try database.write { db in
        try Note
          .searching(searchText)
          .where {
            if let monthsAgo {
              #sql("\($0.dueDate) < date('now', '-\(raw: monthsAgo) months')")
            }
          }
          .delete()
          .execute(db)
      }
    }
  }

  private func updateQuery() async {
    await withErrorReporting {
      try await $notes.load(
        Note
          .searching(searchText)
          .order { $0.dueDate }
          .join(NotesList.all) { $0.notesListID.eq($1.id) }
          .select {
            Row.Columns(
              isPastDue: $0.isPastDue,
              notes: $0.inlineNotes,
              note: $0,
              notesList: $1
            )
          },
        animation: .default
      )
    }
  }

  @Selection
  struct Row: Identifiable {
    var id: Note.ID { note.id }
    let isPastDue: Bool
    let notes: String
    let note: Note
    let notesList: NotesList
  }
}

struct SearchNotesView: View {
  let model: SearchNotesModel

  init(model: SearchNotesModel) {
    self.model = model
  }

  var body: some View {
    ForEach(model.notes) { note in
      NoteRow(
        color: note.notesList.color,
        isPastDue: note.isPastDue,
        notes: note.notes,
        note: note.note,
        notesList: note.notesList
      )
    }
  }
}

#Preview {
  @Previewable @State var searchText = "take"
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }

  NavigationStack {
    List {
      if !searchText.isEmpty {
        SearchNotesView(model: SearchNotesModel())
      } else {
        Text(#"Tap "Search"..."#)
      }
    }
    .searchable(text: $searchText)
  }
}
