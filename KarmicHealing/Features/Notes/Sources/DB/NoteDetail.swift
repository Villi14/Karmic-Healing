// Karmic Healing 2025

import CasePaths
import SharingGRDB
import SwiftUI
import SwiftUINavigation

@MainActor
@Observable
class NotesDetailModel: HashableObject {
  @ObservationIgnored @FetchAll var noteRows: [Row]
  @ObservationIgnored @Shared var ordering: Ordering

  let detailType: DetailType
  var isNewNoteSheetPresented = false

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  init(detailType: DetailType) {
    self.detailType = detailType
    _ordering = Shared(wrappedValue: .dueDate, .appStorage("ordering_list_\(detailType.id)"))
    _noteRows = FetchAll(notesQuery)
  }

  func orderingButtonTapped(_ ordering: Ordering) async {
    $ordering.withLock { $0 = ordering }
    await updateQuery()
  }

  func move(from source: IndexSet, to destination: Int) async {
    withErrorReporting {
      try database.write { db in
        var ids = noteRows.map(\.note.id)
        ids.move(fromOffsets: source, toOffset: destination)
        try Note
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
    $ordering.withLock { $0 = .manual }
    await updateQuery()
  }

  private func updateQuery() async {
    await withErrorReporting {
      try await $noteRows.load(notesQuery, animation: .default)
    }
  }

  private var notesQuery: some StructuredQueriesCore.Statement<Row> {
    let query =
    Note
      .order {
        switch ordering {
        case .dueDate: $0.dueDate.asc(nulls: .last)
        case .manual: $0.position
        case .priority: $0.isFlagged.desc()
        case .title: $0.title
        }
      }
      .join(NotesList.all) { $0.notesListID.eq($1.id) }
      .select {
        Row.Columns(
          note: $0,
          notesList: $1,
          isPastDue: $0.isPastDue,
          notes: $0.inlineNotes.substr(0, 200)
        )
      }
    return query
  }

  enum Ordering: String, CaseIterable {
    case dueDate = "Due Date"
    case manual = "Manual"
    case priority = "Priority"
    case title = "Title"
    var icon: Image {
      switch self {
      case .dueDate: Image(systemName: "calendar")
      case .manual: Image(systemName: "hand.draw")
      case .priority: Image(systemName: "chart.bar.fill")
      case .title: Image(systemName: "textformat.characters")
      }
    }
  }

  @CasePathable
  @dynamicMemberLookup
  enum DetailType: Hashable {
    case all
    case flagged
    case notesList(NotesList)
    case scheduled
    case today
  }

  @Selection
  struct Row: Identifiable {
    var id: Note.ID { note.id }
    let note: Note
    let notesList: NotesList
    let isPastDue: Bool
    let notes: String
  }
}

struct NotesDetailView: View {
  @Bindable var model: NotesDetailModel

  @State var isNavigationTitleVisible = false
  @State var navigationTitleHeight: CGFloat = 36

  var body: some View {
    List {
      VStack(alignment: .leading) {
        GeometryReader { proxy in
          Text(model.detailType.navigationTitle)
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(model.detailType.color)
            .onAppear { navigationTitleHeight = proxy.size.height }
        }
      }
      .listRowSeparator(.hidden)
      ForEach(model.noteRows) { row in
        NoteRow(
          color: model.detailType.color,
          isPastDue: row.isPastDue,
          notes: row.notes,
          note: row.note,
          notesList: row.notesList
        )
      }
      .onMove { source, destination in
        Task { await model.move(from: source, to: destination) }
      }
    }
    .onScrollGeometryChange(for: Bool.self) { geometry in
      geometry.contentOffset.y + geometry.contentInsets.top > navigationTitleHeight
    } action: {
      isNavigationTitleVisible = $1
    }
    .listStyle(.plain)
    .sheet(isPresented: $model.isNewNoteSheetPresented) {
      if let notesList = model.detailType.notesList {
        NavigationStack {
          NoteFormView(
            note: Note.Draft(notesListID: notesList.id),
            notesList: notesList
          )
          .navigationTitle("New Note")
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(model.detailType.navigationTitle)
          .font(.headline)
          .opacity(isNavigationTitleVisible ? 1 : 0)
          .animation(.default.speed(2), value: isNavigationTitleVisible)
      }
      if model.detailType.is(\.notesList) {
        ToolbarItem(placement: .bottomBar) {
          HStack {
            Button {
              model.isNewNoteSheetPresented = true
            } label: {
              HStack {
                Image(systemName: "plus.circle.fill")
                Text("New Note")
              }
              .bold()
              .font(.title3)
            }
            Spacer()
          }
          .tint(model.detailType.color)
        }
      }
      ToolbarItem(placement: .primaryAction) {
        Menu {
          Group {
            Menu {
              ForEach(NotesDetailModel.Ordering.allCases, id: \.self) { ordering in
                Button {
                  Task { await model.orderingButtonTapped(ordering) }
                } label: {
                  Text(ordering.rawValue)
                  ordering.icon
                }
              }
            } label: {
              Text("Sort By")
              Text(model.ordering.rawValue)
              Image(systemName: "arrow.up.arrow.down")
            }
          }
          .tint(model.detailType.color)
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .toolbarTitleDisplayMode(.inline)
  }
}

extension NotesDetailModel.DetailType {
  fileprivate var id: String {
    switch self {
    case .all: "all"
    case .flagged: "flagged"
    case .notesList(let list): "list_\(list.id)"
    case .scheduled: "scheduled"
    case .today: "today"
    }
  }
  fileprivate var navigationTitle: String {
    switch self {
    case .all: "All"
    case .flagged: "Flagged"
    case .notesList(let list): list.title
    case .scheduled: "Scheduled"
    case .today: "Today"
    }
  }
  fileprivate var color: Color {
    switch self {
    case .all: .black
    case .flagged: .orange
    case .notesList(let list): list.color
    case .scheduled: .red
    case .today: .blue
    }
  }
}

struct NotesDetailPreview: PreviewProvider {
  static var previews: some View {
    let notesList = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      return try $0.defaultDatabase.read { db in
        (
          try NotesList.all.fetchOne(db)!
        )
      }
    }
    let detailTypes: [NotesDetailModel.DetailType] = [
      .all,
      .notesList(notesList)
    ]
    ForEach(detailTypes, id: \.self) { detailType in
      NavigationStack {
        NotesDetailView(model: NotesDetailModel(detailType: detailType))
      }
      .previewDisplayName(detailType.navigationTitle)
    }
  }
}

