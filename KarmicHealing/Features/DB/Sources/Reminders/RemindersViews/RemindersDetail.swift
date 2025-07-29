import CasePaths
import SharingGRDB
import SwiftUI
import SwiftUINavigation
import Common
import Resources


@MainActor
@Observable
class RemindersDetailModel: HashableObject {
  @ObservationIgnored @FetchAll var reminderRows: [Row]
  @ObservationIgnored @Shared var ordering: Ordering
  @ObservationIgnored @Shared var showCompleted: Bool

  let detailType: DetailType
  var isNewReminderSheetPresented = false
  var selectedReminderID: UUID?

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  init(detailType: DetailType, selectedReminderID: UUID? = nil) {
    self.detailType = detailType
    self.selectedReminderID = selectedReminderID
    _ordering = Shared(wrappedValue: .dueDate, .appStorage("ordering_list_\(detailType.id)"))
    _showCompleted = Shared(
      wrappedValue: detailType == .completed,
      .appStorage("show_completed_list_\(detailType.id)")
    )
    _reminderRows = FetchAll(remindersQuery)
    // Скролимо до потрібного Reminder, якщо selectedReminderID задано
    if let id = selectedReminderID, let index = reminderRows.firstIndex(where: { $0.id == id }) {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        // TODO: Реалізувати скрол до index (потрібно додати ScrollViewReader у RemindersDetailView)
      }
    }
  }

  func orderingButtonTapped(_ ordering: Ordering) async {
    $ordering.withLock { $0 = ordering }
    await updateQuery()
  }

  func showCompletedButtonTapped() async {
    $showCompleted.withLock { $0.toggle() }
    await updateQuery()
  }

  func move(from source: IndexSet, to destination: Int) async {
    withErrorReporting {
      try database.write { db in
        var ids = reminderRows.map(\.reminder.id)
        ids.move(fromOffsets: source, toOffset: destination)

        try Reminder
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
    await updateQuery()
  }

  private func updateQuery() async {
    await withErrorReporting {
      try await $reminderRows.load(remindersQuery, animation: .default)
    }
  }

  private var remindersQuery: some StructuredQueriesCore.Statement<Row> {
    let query =
    Reminder
      .where {
        if !showCompleted {
          !$0.isCompleted
        }
      }
      .order { $0.isCompleted }
      .order {
        switch ordering {
        case .dueDate: $0.dueDate.asc(nulls: .last)
        case .priority: ($0.priority.desc(), $0.isFlagged.desc())
        case .title: $0.title
        }
      }
      .where { reminder in
        switch detailType {
        case .all: !reminder.isCompleted
        case .completed: reminder.isCompleted
        case .flagged: reminder.isFlagged
        case .remindersList(let list): reminder.remindersListID.eq(list.id)
        case .scheduled: reminder.isScheduled
        case .today: reminder.isToday
        }
      }
      .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
      .select {
        Row.Columns(
          reminder: $0,
          remindersList: $1,
          isPastDue: $0.isPastDue,
          notes: $0.inlineNotes.substr(0, 200)
        )
      }
    return query
  }

  enum Ordering: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case title = "Title"

    var localizedTitle: String {
      switch self {
      case .dueDate:
        return String(localized: "due_date", bundle: .main)
      case .priority:
        return String(localized: "priority", bundle: .main)
      case .title:
        return String(localized: "title", bundle: .main)
      }
    }

    var icon: Image {
      switch self {
      case .dueDate: Image(systemName: "calendar")
      case .priority: Image(systemName: "chart.bar")
      case .title: Image(systemName: "textformat.characters")
      }
    }
  }

  @CasePathable
  @dynamicMemberLookup
  enum DetailType: Hashable {
    case all
    case completed
    case flagged
    case remindersList(RemindersList)
    case scheduled
    case today
  }

  @Selection
  struct Row: Identifiable {
    var id: Reminder.ID { reminder.id }
    let reminder: Reminder
    let remindersList: RemindersList
    let isPastDue: Bool
    let notes: String
  }
}

struct RemindersDetailView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @Bindable var model: RemindersDetailModel

  @State var isNavigationTitleVisible = false
  @State var navigationTitleHeight: CGFloat = 36
  @State private var didScrollToReminder = false

  var body: some View {
    ZStack {
      GgWithGradientView()

      ScrollViewReader { proxy in
        List {
          VStack(alignment: .leading) {
            GeometryReader { proxy in
              Text(model.detailType.navigationTitle)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(model.detailType.color)
                .onAppear { navigationTitleHeight = proxy.size.height }
            }
          }
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)
          .padding(.bottom, DesignConstants.paddingLarge)

          ForEach(model.reminderRows) { row in
            ReminderRow(
              color: model.detailType.color,
              isPastDue: row.isPastDue,
              notes: row.notes,
              reminder: row.reminder,
              remindersList: row.remindersList,
              showCompleted: model.showCompleted
            )
            .id(row.id)
          }
          .listRowBackground(Color.clear)
        }
        .onAppear {
          if let selectedID = model.selectedReminderID, !didScrollToReminder {
            if model.reminderRows.contains(where: { $0.id == selectedID }) {
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                  proxy.scrollTo(selectedID, anchor: .center)
                  didScrollToReminder = true
                }
              }
            }
          }
        }
      }
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.automatic)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          }
        }
      }
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.y + geometry.contentInsets.top > navigationTitleHeight
      } action: {
        isNavigationTitleVisible = $1
      }
      .listStyle(.plain)
      .sheet(isPresented: $model.isNewReminderSheetPresented) {
        if let remindersList = model.detailType.remindersList {
          NavigationStack {
            ReminderFormView(
              reminder: Reminder.Draft(remindersListID: remindersList.id),
              remindersList: remindersList
            )
            .navigationTitle(String(localized: "new_reminder", bundle: .main))
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
        if model.detailType.is(\.remindersList) {
          ToolbarItem(placement: .bottomBar) {
            HStack {
              Button {
                model.isNewReminderSheetPresented = true
              } label: {
                HStack {
                  Image(systemName: "plus")
                  Text(String(localized: "reminder", bundle: .main))
                }
                .font(.body)
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
                ForEach(RemindersDetailModel.Ordering.allCases, id: \.self) { ordering in
                  Button {
                    Task { await model.orderingButtonTapped(ordering) }
                  } label: {
                    Text(ordering.localizedTitle)
                    ordering.icon
                  }
                }
              } label: {
                Text(String(localized: "sort_by", bundle: .main))
                Text(model.ordering.localizedTitle)
                Image(systemName: "arrow.up.arrow.down")
              }

              Button {
                Task { await model.showCompletedButtonTapped() }
              } label: {
                Text(model.showCompleted ? String(localized: "hide_completed", bundle: .main) : String(localized: "show_completed", bundle: .main))
                Image(systemName: model.showCompleted ? "eye" : "eye")
              }
            }
            .tint(model.detailType.color)
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
      .tint(ResourcesAsset.Colors.clam.swiftUIColor)
    }
  }
}

extension RemindersDetailModel.DetailType {
  fileprivate var id: String {
    switch self {
    case .all: "all"
    case .completed: "completed"
    case .flagged: "flagged"
    case .remindersList(let list): "list_\(list.id)"
    case .scheduled: "scheduled"
    case .today: "today"
    }
  }

  fileprivate var navigationTitle: String {
    switch self {
    case .all: String(localized: "all", bundle: .main)
    case .completed: String(localized: "completed", bundle: .main)
    case .flagged: String(localized: "flagged", bundle: .main)
    case .remindersList(let list): list.title
    case .scheduled: String(localized: "scheduled", bundle: .main)
    case .today: String(localized: "today", bundle: .main)
    }
  }

  fileprivate var color: Color {
    switch self {
    case .all: ResourcesAsset.Colors.textPrimary.swiftUIColor
    case .completed: ResourcesAsset.Colors.health.swiftUIColor
    case .flagged: ResourcesAsset.Colors.friendly.swiftUIColor
    case .remindersList(let list): list.color
    case .scheduled: ResourcesAsset.Colors.error.swiftUIColor
    case .today: ResourcesAsset.Colors.clam.swiftUIColor
    }
  }
}

struct RemindersDetailPreview: PreviewProvider {
  static var previews: some View {
    let remindersList = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      return try $0.defaultDatabase.read { db in
        (
          try RemindersList.all.fetchOne(db)!,
        )
      }
    }

    let detailTypes: [RemindersDetailModel.DetailType] = [
      .all,
      .remindersList(remindersList)
    ]

    ForEach(detailTypes, id: \.self) { detailType in
      NavigationStack {
        RemindersDetailView(model: RemindersDetailModel(detailType: detailType))
      }
      .previewDisplayName(detailType.navigationTitle)
    }
  }
}
