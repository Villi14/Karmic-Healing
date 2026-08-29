import CasePaths
import SQLiteData
import Sharing
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
  @ObservationIgnored @Dependency(\.defaultDatabase) private var database
  
  let detailType: DetailType
  var isNewReminderSheetPresented = false
  var selectedReminderID: UUID?
  
  init(detailType: DetailType, selectedReminderID: UUID? = nil) {
    self.detailType = detailType
    self.selectedReminderID = selectedReminderID
    _ordering = Shared(wrappedValue: .dueDate, .appStorage("ordering_list_\(detailType.id)"))
    _showCompleted = Shared(
      wrappedValue: detailType == .completed,
      .appStorage("show_completed_list_\(detailType.id)")
    )
    _reminderRows = FetchAll(remindersQuery)
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
    _ = await withErrorReporting {
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
        return "due_date".loc
      case .priority:
        return "priority".loc
      case .title:
        return "title".loc
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
      AuraBackground(level: .solar)
      
      ScrollViewReader { proxy in
        List {
          VStack(alignment: .leading, spacing: DesignConstants.spacingSmall) {
            // A topic's screen names itself as one; the mixed screens leave the eyebrow off.
            if model.detailType.is(\.remindersList) {
              Text("topic".loc)
                .karmicLabel(tone: model.detailType.color)
            }

            Text(model.detailType.navigationTitle)
              .font(Typography.title)
              .foregroundStyle(model.detailType.color)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
              .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                navigationTitleHeight = $0
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
              showCompleted: model.showCompleted,
              showsTopic: !model.detailType.is(\.remindersList)
            )
            .id(row.id)
          }
          .listRowBackground(Color.clear)
        }
        .onAppear {
          if let selectedID = model.selectedReminderID, !didScrollToReminder {
            if model.reminderRows.contains(where: { $0.id == selectedID }) {
              Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(500))
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
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .solar))
          }
        }
      }
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.y + geometry.contentInsets.top > navigationTitleHeight
      } action: {
        isNavigationTitleVisible = $1
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .karmicContentWidth()
      .sheet(isPresented: $model.isNewReminderSheetPresented) {
        if let remindersList = model.detailType.remindersList {
          NavigationStack {
            ReminderFormView(
              reminder: Reminder.Draft(remindersListID: remindersList.id),
              remindersList: remindersList,
              title: "new_reminder".loc
            )
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(model.detailType.navigationTitle)
            .font(Typography.title)
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
                  Text("reminder".loc)
                }
                .font(Typography.body)
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
                Text("sort_by".loc)
                Text(model.ordering.localizedTitle)
                Image(systemName: "arrow.up.arrow.down")
              }
              
              Button {
                Task { await model.showCompletedButtonTapped() }
              } label: {
                Text(model.showCompleted ? "hide_completed".loc : "show_completed".loc)
                Image(systemName: model.showCompleted ? "eye" : "eye")
              }
            }
            .tint(model.detailType.color)
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
      .tint(Spectrum.solar.color)
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
    case .all: "all".loc
    case .completed: "completed".loc
    case .flagged: "flagged".loc
    case .remindersList(let list): list.title
    case .scheduled: "scheduled".loc
    case .today: "today".loc
    }
  }
  
  fileprivate var color: Color {
    switch self {
    case .all: ResourcesAsset.Colors.textPrimary.swiftUIColor
    case .completed: ResourcesAsset.Colors.health.swiftUIColor
    case .flagged: ResourcesAsset.Colors.friendly.swiftUIColor
    case .remindersList(let list): list.color
    case .scheduled: ResourcesAsset.Colors.energy.swiftUIColor
    case .today: Spectrum.solar.color
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
