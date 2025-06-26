// Karmic Healing 2025

import SharingGRDB
import SwiftUI

struct NotesListRow: View {
  let notesCount: Int
  let notesList: NotesList

  @State var editList: NotesList?

  @Dependency(\.defaultDatabase) private var database

  var body: some View {
    HStack {
      Image(systemName: "list.bullet.circle.fill")
        .font(.largeTitle)
        .foregroundStyle(notesList.color)
        .background(
          Color.white.clipShape(Circle()).padding(4)
        )
      Text(notesList.title)
      Spacer()
      Text("\(notesCount)")
        .foregroundStyle(.gray)
    }
    .swipeActions {
      Button {
        withErrorReporting {
          try database.write { db in
            try NotesList.delete(notesList)
              .execute(db)
          }
        }
      } label: {
        Image(systemName: "trash")
      }
      .tint(.red)
      Button {
        editList = notesList
      } label: {
        Image(systemName: "info.circle")
      }
    }
    .sheet(item: $editList) { list in
      NavigationStack {
        NotesListForm(notesList: NotesList.Draft(list))
          .navigationTitle("Edit list")
      }
      .presentationDetents([.medium])
    }
  }
}

#Preview {
  NavigationStack {
    List {
      NotesListRow(
        notesCount: 10,
        notesList: NotesList(
          id: UUID(),
          title: "Personal"
        )
      )
    }
  }
}

