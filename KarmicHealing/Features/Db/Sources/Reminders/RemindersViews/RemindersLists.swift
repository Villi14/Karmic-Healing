import SQLiteData
import SwiftUI
import SwiftUINavigation
import TipKit
import Common
import Resources

@MainActor
@Observable
class RemindersListsModel {
  @ObservationIgnored
  @FetchAll(
    RemindersList
      .group(by: \.id)
      .order(by: \.position)
      .leftJoin(Reminder.all) { $0.id.eq($1.remindersListID) && !$1.isCompleted }
      .select {
        ReminderListState.Columns(remindersCount: $1.id.count(), remindersList: $0)
      },
    animation: .default
  )
  var remindersLists

  @ObservationIgnored
  @FetchOne(
    Reminder.select {
      Stats.Columns(
        allCount: $0.count(filter: !$0.isCompleted),
        flaggedCount: $0.count(filter: $0.isFlagged),
        scheduledCount: $0.count(filter: $0.isScheduled),
        todayCount: $0.count(filter: $0.isToday)
      )
    }
  )
  var stats = Stats()

  var destination: Destination?
  var searchRemindersModel = SearchRemindersModel()
#if DEBUG
  var seedDatabaseTip: SeedDatabaseTip?
#endif
  var shouldOpenReminderFormFromNotification = false
  var selectedReminderID: UUID?
  var selectedReminderListID: UUID?

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

  /// The ids come from the navigation state that opened this screen; they are consumed
  /// once in `onAppear` so returning to the list does not re-open the detail.
  init(selectedReminderID: UUID? = nil, selectedReminderListID: UUID? = nil) {
    self.selectedReminderID = selectedReminderID
    self.selectedReminderListID = selectedReminderListID
  }

  func statTapped(_ detailType: RemindersDetailModel.DetailType) {
    destination = .detail(RemindersDetailModel(detailType: detailType))
  }

  func remindersListTapped(remindersList: RemindersList) {
    destination = .detail(
      RemindersDetailModel(
        detailType: .remindersList(
          remindersList
        )
      )
    )
  }

  func onAppear() {
    withErrorReporting {
      try Tips.configure()
    }
#if DEBUG
    if remindersLists.isEmpty {
      seedDatabaseTip = SeedDatabaseTip()
    }
#endif

    // Check if we need to open form through notification
    if shouldOpenReminderFormFromNotification {
      shouldOpenReminderFormFromNotification = false
      openReminderFormFromNotification()
    }

    // Check if we need to open RemindersDetailView with selectedReminderID
    if let selectedReminderID {
      openRemindersDetailWithSelectedReminder(selectedReminderID)
      // Consume the deep link so coming back to the list does not re-open the detail.
      self.selectedReminderID = nil
      self.selectedReminderListID = nil
    }
  }

  func newReminderButtonTapped() {
    // This function is only called when there are lists, so we can safely unwrap
    guard let remindersList = remindersLists.first?.remindersList else { return }

    destination = .reminderForm(
      Reminder.Draft(remindersListID: remindersList.id),
      remindersList: remindersList
    )
  }

  func addListButtonTapped() {
    destination = .remindersListForm(RemindersList.Draft())
  }

  func listDetailsButtonTapped(remindersList: RemindersList) {
    destination = .remindersListForm(RemindersList.Draft(remindersList))
  }

  func openReminderFormFromNotification() {
    guard let _ = remindersLists.first?.remindersList
    else {
      reportIssue("There must be at least one list.")
      return
    }
  }

  func openRemindersDetailWithSelectedReminder(_ reminderID: UUID) {
    // Try to find the specific list if selectedReminderListID is provided
    let targetRemindersList: RemindersList
    if let selectedReminderListID = selectedReminderListID,
       let foundList = remindersLists.first(where: { $0.remindersList.id == selectedReminderListID })?.remindersList {
      targetRemindersList = foundList
    } else {
      // Fallback to first list if no specific list is found
      guard let remindersList = remindersLists.first?.remindersList
      else {
        reportIssue("There must be at least one list.")
        return
      }
      targetRemindersList = remindersList
    }

    destination = .detail(
      RemindersDetailModel(
        detailType: .remindersList(targetRemindersList),
        selectedReminderID: reminderID
      )
    )
  }

  func move(from source: IndexSet, to destination: Int) {
    withErrorReporting {
      try database.write { db in
        var ids = remindersLists.map(\.remindersList.id)
        ids.move(fromOffsets: source, toOffset: destination)
        try RemindersList
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
    case detail(RemindersDetailModel)
    case reminderForm(Reminder.Draft, remindersList: RemindersList)
    case remindersListForm(RemindersList.Draft)
  }

  @Selection
  struct ReminderListState: Identifiable {
    var id: RemindersList.ID { remindersList.id }
    var remindersCount: Int
    var remindersList: RemindersList
  }

  @Selection
  struct Stats {
    var allCount = 0
    var flaggedCount = 0
    var scheduledCount = 0
    var todayCount = 0
  }

#if DEBUG
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
#endif
}

struct RemindersListsView: View {
  @Bindable var model: RemindersListsModel

  var body: some View {
    ZStack {
      AuraBackground(level: .solar)

      VStack(spacing: 0) {
        SearchBar(text: $model.searchRemindersModel.searchText)
        List {
          if model.searchRemindersModel.searchText.isEmpty {
            if model.remindersLists.isEmpty {
              KarmicEmptyStateView(
                iconName: "bell",
                title: "reminders_empty_title".loc,
                message: "reminders_empty_message".loc,
                tone: Spectrum.solar.color,
                level: .solar,
                actionTitle: "add_list".loc,
                action: { model.addListButtonTapped() }
              )
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
              .listRowInsets(EdgeInsets())
            } else {
              Section {
                Grid(alignment: .leading, horizontalSpacing: DesignConstants.padding, verticalSpacing: DesignConstants.padding) {
                  GridRow {
                    GridCell(
                      color: Spectrum.solar.color,
                      count: model.stats.todayCount,
                      iconName: "calendar",
                      title: "today".loc,
                      level: .solar
                    ) {
                      model.statTapped(.today)
                    }

                    GridCell(
                      color: ResourcesAsset.Colors.energy.swiftUIColor,
                      count: model.stats.scheduledCount,
                      iconName: "calendar",
                      title: "scheduled".loc,
                      level: .root
                    ) {
                      model.statTapped(.scheduled)
                    }
                  }

                  GridRow {
                    GridCell(
                      color: ResourcesAsset.Colors.textSecondary.swiftUIColor,
                      count: model.stats.allCount,
                      iconName: "tray",
                      title: "all".loc,
                      level: .throat
                    ) {
                      model.statTapped(.all)
                    }

                    GridCell(
                      color: ResourcesAsset.Colors.friendly.swiftUIColor,
                      count: model.stats.flaggedCount,
                      iconName: "flag",
                      title: "flagged".loc,
                      level: .sacral
                    ) {
                      model.statTapped(.flagged)
                    }
                  }

                  GridRow {
                    GridCell(
                      color: ResourcesAsset.Colors.health.swiftUIColor,
                      count: nil,
                      iconName: "checkmark",
                      title: "completed".loc,
                      level: .heart
                    ) {
                      model.statTapped(.completed)
                    }
                  }
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .padding(.horizontal, DesignConstants.paddingNegative)
              }
              .listSectionSeparator(.hidden)

              Section {
                ForEach(model.remindersLists) { state in
                  RemindersListRow(
                    remindersCount: state.remindersCount,
                    remindersList: state.remindersList,
                    onTap: {
                      model.remindersListTapped(remindersList: state.remindersList)
                    }
                  )
                }
              } header: {
                VStack(alignment: .leading, spacing: DesignConstants.spacingSmall) {
                  Text("my_reminders".loc)
                    .font(Typography.title)
                    .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

                  // A list here is a topic, so the header says out loud what the rows below are.
                  Text("topics_hint".loc)
                    .font(Typography.bodySecondary)
                    .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .textCase(nil)
                .padding(.top, DesignConstants.paddingNegativeLarge)
                .padding(.horizontal, DesignConstants.paddingSmall)
              }
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
              .listRowInsets(EdgeInsets(
                top: DesignConstants.paddingSmall,
                leading: DesignConstants.paddingMedium,
                bottom: DesignConstants.paddingSmall,
                trailing: DesignConstants.paddingMedium)
              )
            }
          } else {
            SearchRemindersView(model: model.searchRemindersModel)
              .listRowBackground(Color.clear)
          }
        }
        .onAppear {
          model.onAppear()
        }

        .toolbar {
#if DEBUG
          ToolbarItem(placement: .automatic) {
            Menu {
              Button {
                model.seedDatabaseButtonTapped()
              } label: {
                Text("seed_data".loc)
                  .foregroundStyle(AuraGradient.gradient(for: .solar))

                Image(systemName: "leaf")
                  .foregroundStyle(AuraGradient.gradient(for: .solar))
              }
            } label: {
              Image(systemName: "ellipsis")
                .foregroundStyle(AuraGradient.gradient(for: .solar))
            }
            .popoverTip(model.seedDatabaseTip)
          }
#endif
          ToolbarItem(placement: .bottomBar) {
            HStack {
              // Only show "Plus Reminder" button if there are lists
              if !model.remindersLists.isEmpty {
                Button {
                  model.newReminderButtonTapped()
                } label: {
                  HStack {
                    Image(systemName: "plus")
                      .foregroundStyle(AuraGradient.gradient(for: .solar))

                    Text("reminder".loc)
                      .font(Typography.body)
                      .foregroundStyle(AuraGradient.gradient(for: .solar))
                  }
                }

                Spacer()
              } else {
                Spacer()
              }

              Button {
                model.addListButtonTapped()
              } label: {
                Image(systemName: "plus")
                  .foregroundStyle(AuraGradient.gradient(for: .solar))

                Text("list".loc)
                  .font(Typography.body)
                  .foregroundStyle(AuraGradient.gradient(for: .solar))
              }
            }
          }
        }
        .sheet(item: $model.destination.reminderForm, id: \.0.id) { reminder, remindersList in
          NavigationStack {
            ReminderFormView(
              reminder: reminder,
              remindersList: remindersList,
              title: "new_reminder".loc
            )
          }
        }
        .sheet(item: $model.destination.remindersListForm) { remindersList in
          NavigationStack {
            RemindersListForm(remindersList: remindersList, title: "new_list".loc)
          }
          .presentationDetents([.large])
        }
        .tint(Spectrum.solar.color)
        .navigationDestination(item: $model.destination.detail) { detailModel in
          RemindersDetailView(model: detailModel)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, DesignConstants.padding)
        .padding(.top, DesignConstants.padding)
      }
      .karmicContentWidth()
    }
  }
}

#Preview {
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }
  ZStack {
    AuraBackground(level: .solar)
    NavigationStack {
      RemindersListsView(model: RemindersListsModel())
    }
  }
}
