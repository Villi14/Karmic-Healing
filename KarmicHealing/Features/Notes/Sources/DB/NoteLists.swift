// Karmic Healing 2025

import SharingGRDB
import SwiftUI
import SwiftUINavigation
import TipKit

@MainActor
@Observable
class NotesListsModel {
  @ObservationIgnored
  @FetchAll(
    NotesList
      .group(by: \.id)
      .order(by: \.position)
      .leftJoin(Note.all) { $0.id.eq($1.notesListID) }
      .select {
        NoteListState.Columns(notesCount: $1.id.count(), notesList: $0)
      },
    animation: .default
  )
  var notesLists

  @ObservationIgnored
  @FetchOne(
    Note.select {
      Stats.Columns(
        allCount: $0.count(filter: true),
        flaggedCount: $0.count(filter: $0.isFlagged),
        scheduledCount: $0.count(filter: $0.isScheduled),
        todayCount: $0.count(filter: $0.isToday)
      )
    }
  )
  var stats = Stats()

  var destination: Destination?
  var searchNotesModel = SearchNotesModel()
  var seedDatabaseTip: SeedDatabaseTip?

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  func statTapped(_ detailType: NotesDetailModel.DetailType) {
    destination = .detail(NotesDetailModel(detailType: detailType))
  }

  func notesListTapped(notesList: NotesList) {
    destination = .detail(
      NotesDetailModel(
        detailType: .notesList(
          notesList
        )
      )
    )
  }

  func onAppear() {
    withErrorReporting {
      try Tips.configure()
    }
    if notesLists.isEmpty {
      seedDatabaseTip = SeedDatabaseTip()
    }
  }

  func newNoteButtonTapped() {
    guard let notesList = notesLists.first?.notesList
    else {
      reportIssue("There must be at least one list.")
      return
    }
    destination = .noteForm(
      Note.Draft(notesListID: notesList.id),
      notesList: notesList
    )
  }

  func addListButtonTapped() {
    destination = .notesListForm(NotesList.Draft())
  }

  func listDetailsButtonTapped(notesList: NotesList) {
    destination = .notesListForm(NotesList.Draft(notesList))
  }

  func move(from source: IndexSet, to destination: Int) {
    withErrorReporting {
      try database.write { db in
        var ids = notesLists.map(\.notesList.id)
        ids.move(fromOffsets: source, toOffset: destination)
        try NotesList
          .where { $0.id.in(ids) }
          .update {
            let ids = Array(ids.enumerated())
            let (first, rest) = (ids.first!, ids.dropFirst())
            $0.position =
            rest
              .reduce(Case($0.id).when(first.element, then: first.offset)) { cases, id in
                cases.when(id.element, then: id.offset)
              }
              .else($0.position)
          }
          .execute(db)
      }
    }
  }

  #if DEBUG
  func seedDatabaseButtonTapped() {
    withErrorReporting {
      try database.write { db in
        try db.seedSampleData()
      }
    }
  }
  #endif

  @CasePathable
  enum Destination {
    case detail(NotesDetailModel)
    case noteForm(Note.Draft, notesList: NotesList)
    case notesListForm(NotesList.Draft)
  }

  @Selection
  struct NoteListState: Identifiable {
    var id: NotesList.ID { notesList.id }
    var notesCount: Int
    var notesList: NotesList
  }

  @Selection
  struct Stats {
    var allCount = 0
    var flaggedCount = 0
    var scheduledCount = 0
    var todayCount = 0
  }

  struct SeedDatabaseTip: Tip {
    var title: Text {
      Text("Seed Sample Data")
    }
    var message: Text? {
      Text("Tap here to quickly populate the app with test data.")
    }
    var image: Image? {
      Image(systemName: "leaf")
    }
  }
}

struct NotesListsView: View {
  @Bindable var model: NotesListsModel

  var body: some View {
    List {
      if model.searchNotesModel.searchText.isEmpty {
        Section {
          Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 16) {
            GridRow {
              NoteGridCell(
                color: .blue,
                count: model.stats.todayCount,
                iconName: "calendar.circle.fill",
                title: "Today"
              ) {
                model.statTapped(.today)
              }
              NoteGridCell(
                color: .red,
                count: model.stats.scheduledCount,
                iconName: "calendar.circle.fill",
                title: "Scheduled"
              ) {
                model.statTapped(.scheduled)
              }
            }
            GridRow {
              NoteGridCell(
                color: .gray,
                count: model.stats.allCount,
                iconName: "tray.circle.fill",
                title: "All"
              ) {
                model.statTapped(.all)
              }
              NoteGridCell(
                color: .orange,
                count: model.stats.flaggedCount,
                iconName: "flag.circle.fill",
                title: "Flagged"
              ) {
                model.statTapped(.flagged)
              }
            }
          }
          .buttonStyle(.plain)
          .listRowBackground(Color.clear)
          .padding([.leading, .trailing], -20)
        }

        Section {
          ForEach(model.notesLists) { state in
            Button {
              model.notesListTapped(notesList: state.notesList)
            } label: {
              NotesListRow(
                notesCount: state.notesCount,
                notesList: state.notesList
              )
            }
            .foregroundStyle(.primary)
          }
          .onMove(perform: model.move(from:to:))
        } header: {
          Text("My Lists")
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(Color(.label))
            .textCase(nil)
            .padding(.top, -16)
            .padding([.leading, .trailing], 4)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
      } else {
        SearchNotesView(model: model.searchNotesModel)
      }
    }
    .onAppear {
      model.onAppear()
    }
    .listStyle(.insetGrouped)
    .toolbar {
      #if DEBUG
      ToolbarItem(placement: .automatic) {
          Menu {
            Button {
              model.seedDatabaseButtonTapped()
            } label: {
              Text("Seed data")
              Image(systemName: "leaf")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
          .popoverTip(model.seedDatabaseTip)
        }
      #endif
      ToolbarItem(placement: .bottomBar) {
        HStack {
          Button {
            model.newNoteButtonTapped()
          } label: {
            HStack {
              Image(systemName: "plus.circle.fill")
              Text("New Note")
            }
            .bold()
            .font(.title3)
          }
          Spacer()
          Button {
            model.addListButtonTapped()
          } label: {
            Text("Add List")
              .font(.title3)
          }
        }
      }
    }
    .sheet(item: $model.destination.noteForm, id: \.0.id) { note, notesList in
      NavigationStack {
        NoteFormView(note: note, notesList: notesList)
          .navigationTitle("New Note")
      }
    }
    .sheet(item: $model.destination.notesListForm) { notesList in
      NavigationStack {
        NotesListForm(notesList: notesList)
          .navigationTitle("New List")
      }
      .presentationDetents([.medium])
    }
    .searchable(text: $model.searchNotesModel.searchText)
    .navigationDestination(item: $model.destination.detail) { detailModel in
      NotesDetailView(model: detailModel)
    }
  }
}

private struct NoteGridCell: View {
  let color: Color
  let count: Int?
  let iconName: String
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 8) {
          Image(systemName: iconName)
            .font(.largeTitle)
            .bold()
            .foregroundStyle(color)
            .background(
              Color.white.clipShape(Circle()).padding(4)
            )
          Text(title)
            .font(.headline)
            .foregroundStyle(.gray)
            .bold()
            .padding(.leading, 4)
        }
        Spacer()
        if let count {
          Text("\(count)")
            .font(.largeTitle)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(Color(.label))
        }
      }
      .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
      .background(Color(.secondarySystemGroupedBackground))
      .cornerRadius(10)
    }
  }
}

#Preview {
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }
  NavigationStack {
    NotesListsView(model: NotesListsModel())
  }
}

