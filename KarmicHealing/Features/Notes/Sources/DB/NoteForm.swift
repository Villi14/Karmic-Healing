// Karmic Healing 2025

import IssueReporting
import SharingGRDB
import SwiftUI

struct NoteFormView: View {
  @FetchAll(NotesList.order(by: \.title)) var notesLists
  @FetchOne var notesList: NotesList
  
  @State var note: Note.Draft

  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss

  init(note: Note.Draft, notesList: NotesList) {
    _notesList = FetchOne(wrappedValue: notesList, NotesList.find(notesList.id))
    self.note = note
  }

  var body: some View {
    Form {
      TextField("Title", text: $note.title)

      ZStack {
        if note.notes.isEmpty {
          TextEditor(text: .constant("Notes"))
            .foregroundStyle(.placeholder)
            .accessibilityHidden(true, isEnabled: false)
        }

        TextEditor(text: $note.notes)
      }
      .lineLimit(4)
      .padding([.leading, .trailing], -5)

      Section {
        Toggle(isOn: $note.isDateSet.animation()) {
          HStack {
            Image(systemName: "calendar.circle.fill")
              .font(.title)
              .foregroundStyle(.red)
            Text("Date")
          }
        }
        if let dueDate = note.dueDate {
          DatePicker(
            "",
            selection: $note.dueDate[coalesce: dueDate],
            displayedComponents: [.date, .hourAndMinute]
          )
          .padding([.top, .bottom], 2)
        }
      }

      Section {
        Toggle(isOn: $note.isFlagged) {
          HStack {
            Image(systemName: "flag.circle.fill")
              .font(.title)
              .foregroundStyle(.red)
            Text("Flag")
          }
        }

        Picker(selection: $note.notesListID) {
          ForEach(notesLists) { notesList in
            Text(notesList.title)
              .tag(notesList)
              .buttonStyle(.plain)
              .tag(notesList.id)
          }
        } label: {
          HStack {
            Image(systemName: "list.bullet.circle.fill")
              .font(.title)
              .foregroundStyle(notesList.color)
            Text("List")
          }
        }
        .task(id: note.notesListID) {
          await withErrorReporting {
            try await $notesList.load(NotesList.find(note.notesListID))
          }
        }
      }
    }
    .padding(.top, -28)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button(action: saveButtonTapped) {
          Text("Save")
        }
      }
      ToolbarItem(placement: .cancellationAction) {
        Button("Cancel") {
          dismiss()
        }
      }
    }
  }

  private func saveButtonTapped() {
    withErrorReporting {
      try database.write { db in
        var note = note
        let noteID = try Note.upsert(note).returning(\.id).fetchOne(db)!
          //.execute(db)
      }
    }
    dismiss()
  }
}

extension Note.Draft {
  fileprivate var isDateSet: Bool {
    get { dueDate != nil }
    set { dueDate = newValue ? Date() : nil }
  }
}

extension Optional {
  fileprivate subscript(coalesce coalesce: Wrapped) -> Wrapped {
    get { self ?? coalesce }
    set { self = newValue }
  }
}

struct NoteFormPreview: PreviewProvider {
  static var previews: some View {
    let (notesList, note) = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      return try $0.defaultDatabase.write { db in
        let notesList = try NotesList.all.fetchOne(db)!
        return (
          notesList,
          try Note.where { $0.notesListID == notesList.id }.fetchOne(db)!
        )
      }
    }
    NavigationStack {
      NoteFormView(note: Note.Draft(note), notesList: notesList)
        .navigationTitle("Detail")
    }
  }
}

