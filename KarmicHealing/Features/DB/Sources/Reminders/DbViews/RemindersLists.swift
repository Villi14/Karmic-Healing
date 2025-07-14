import SharingGRDB
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
  var seedDatabaseTip: SeedDatabaseTip?

  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database

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
    if remindersLists.isEmpty {
      seedDatabaseTip = SeedDatabaseTip()
    }
    searchRemindersModel.searchText = ""
  }

  func newReminderButtonTapped() {
    guard let remindersList = remindersLists.first?.remindersList
    else {
      reportIssue("There must be at least one list.")
      return
    }
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

struct RemindersListsView: View {
  @Bindable var model: RemindersListsModel

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [
          ResourcesAsset.Colors.clam.swiftUIColor.opacity(DesignConstants.opacityLow),
          ResourcesAsset.Colors.background.swiftUIColor
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        KarmicHealingSearchBar(text: $model.searchRemindersModel.searchText)
        List {
          if model.searchRemindersModel.searchText.isEmpty {
            Section {
              Grid(alignment: .leading, horizontalSpacing: DesignConstants.padding, verticalSpacing: DesignConstants.padding) {
                GridRow {
                  KarmicHealingGridCell(
                    color: ResourcesAsset.Colors.clam.swiftUIColor,
                    count: model.stats.todayCount,
                    iconName: "calendar",
                    title: String(localized: "today", bundle: .main)
                  ) {
                    model.statTapped(.today)
                  }

                  KarmicHealingGridCell(
                    color: ResourcesAsset.Colors.energy.swiftUIColor,
                    count: model.stats.scheduledCount,
                    iconName: "calendar",
                    title: String(localized: "scheduled", bundle: .main)
                  ) {
                    model.statTapped(.scheduled)
                  }
                }

                GridRow {
                  KarmicHealingGridCell(
                    color: ResourcesAsset.Colors.textSecondary.swiftUIColor,
                    count: model.stats.allCount,
                    iconName: "tray",
                    title: String(localized: "all", bundle: .main)
                  ) {
                    model.statTapped(.all)
                  }

                  KarmicHealingGridCell(
                    color: ResourcesAsset.Colors.friendly.swiftUIColor,
                    count: model.stats.flaggedCount,
                    iconName: "flag",
                    title: String(localized: "flagged", bundle: .main)
                  ) {
                    model.statTapped(.flagged)
                  }
                }

                GridRow {
                  KarmicHealingGridCell(
                    color: ResourcesAsset.Colors.health.swiftUIColor,
                    count: nil,
                    iconName: "checkmark",
                    title: String(localized: "completed", bundle: .main)
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
              Text(String(localized: "my_reminders", bundle: .main))
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
                .textCase(nil)
                .padding(.top, DesignConstants.paddingNegativeLarge)
                .padding(.horizontal, DesignConstants.paddingSmall)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 2, leading: 12, bottom: 2, trailing: 12))
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
                Text(String(localized: "seed_data", bundle: .main))
                  .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)

                Image(systemName: "leaf")
                  .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
              }
            } label: {
              Image(systemName: "ellipsis")
                .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
            }
            .popoverTip(model.seedDatabaseTip)
          }
#endif
          ToolbarItem(placement: .bottomBar) {
            HStack {
              Button {
                model.newReminderButtonTapped()
              } label: {
                HStack {
                  Image(systemName: "plus")
                    .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)

                  Text(String(localized: "reminder", bundle: .main))
                    .font(.body)
                    .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
                }
              }

              Spacer()

              Button {
                model.addListButtonTapped()
              } label: {
                Image(systemName: "plus")
                  .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)

                Text(String(localized: "list", bundle: .main))
                  .font(.body)
                  .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
              }
            }
          }
        }
        .sheet(item: $model.destination.reminderForm, id: \.0.id) { reminder, remindersList in
          NavigationStack {
            ReminderFormView(reminder: reminder, remindersList: remindersList)
              .navigationTitle(String(localized: "new_reminder", bundle: .main))
          }
        }
        .sheet(item: $model.destination.remindersListForm) { remindersList in
          NavigationStack {
            RemindersListForm(remindersList: remindersList)
              .navigationTitle(String(localized: "new_list", bundle: .main))
          }
          .presentationDetents([.medium])
        }
        .tint(ResourcesAsset.Colors.clam.swiftUIColor)
        .navigationDestination(item: $model.destination.detail) { detailModel in
          RemindersDetailView(model: detailModel)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, DesignConstants.padding)
        .padding(.top, DesignConstants.padding)
      }
    }
  }
}

#Preview {
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }

  NavigationStack {
    RemindersListsView(model: RemindersListsModel())
  }
}
