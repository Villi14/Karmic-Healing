// Karmic Healing 2025

import IssueReporting
import SharingGRDB
import SwiftUI

struct NotesListForm: View {
  @Dependency(\.defaultDatabase) private var database

  @State var notesList: NotesList.Draft
  @Environment(\.dismiss) var dismiss

  init(notesList: NotesList.Draft) {
    self.notesList = notesList
  }

  var body: some View {
    Form {
      Section {
        VStack {
          TextField("List Name", text: $notesList.title)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(notesList.color)
            .multilineTextAlignment(.center)
            .padding()
            .textFieldStyle(.plain)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(.buttonBorder)
      }
      ColorPicker("Color", selection: $notesList.color)
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("Save") {
          withErrorReporting {
            try database.write { db in
              try NotesList.upsert(notesList)
                .execute(db)
            }
          }
          dismiss()
        }
      }
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
    }
  }
}

struct NotesListFormPreviews: PreviewProvider {
  static var previews: some View {
    let _ = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
    }
    NavigationStack {
      NotesListForm(notesList: NotesList.Draft())
        .navigationTitle("New List")
    }
  }
}

