import IssueReporting
import SharingGRDB
import SwiftUI

@MainActor
@Observable
class SearchRemindersModel {
  var showCompletedInSearchResults = false
  var searchText = "" {
    didSet {
      Task { await updateQuery() }
    }
  }

  @ObservationIgnored @FetchOne var completedCount: Int = 0
  @ObservationIgnored @FetchAll var reminders: [Row]

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  func showCompletedButtonTapped() async {
    showCompletedInSearchResults.toggle()
    await updateQuery()
  }

  func deleteCompletedReminders(monthsAgo: Int? = nil) {
    withErrorReporting {
      try database.write { db in
        try Reminder
          .searching(searchText)
          .where(\.isCompleted)
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
      if searchText.isEmpty {
        showCompletedInSearchResults = false
      }

      try await $completedCount.load(
        Reminder.searching(searchText)
          .where(\.isCompleted)
          .count(),
        animation: .default
      )

      try await $reminders.load(
        Reminder
          .searching(searchText)
          .where {
            if !showCompletedInSearchResults {
              !$0.isCompleted
            }
          }
          .order { ($0.isCompleted, $0.dueDate) }
          .join(RemindersList.all) { $0.remindersListID.eq($1.id) }
          .select {
            Row.Columns(
              isPastDue: $0.isPastDue,
              notes: $0.inlineNotes,
              reminder: $0,
              remindersList: $1
            )
          },
        animation: .default
      )
    }
  }

  @Selection
  struct Row: Identifiable {
    var id: Reminder.ID { reminder.id }
    let isPastDue: Bool
    let notes: String
    let reminder: Reminder
    let remindersList: RemindersList
  }
}

struct SearchRemindersView: View {
  let model: SearchRemindersModel

  init(model: SearchRemindersModel) {
    self.model = model
  }

  var body: some View {
    HStack {
      Text("\(model.completedCount) " + String(localized: "completed", bundle: .main))
        .monospacedDigit()
        .contentTransition(.numericText())
      if model.completedCount > 0 {
        Text("•")
        Menu {
          Text(String(localized: "clear_completed_reminders", bundle: .main))
          Button(String(localized: "older_than_1_month", bundle: .main)) {
            model.deleteCompletedReminders(monthsAgo: 1)
          }

          Button(String(localized: "older_than_6_months", bundle: .main)) {
            model.deleteCompletedReminders(monthsAgo: 6)
          }

          Button(String(localized: "older_than_1_year", bundle: .main)) {
            model.deleteCompletedReminders(monthsAgo: 12)
          }

          Button(String(localized: "all_completed", bundle: .main)) {
            model.deleteCompletedReminders()
          }
        } label: {
          Text(String(localized: "clear", bundle: .main))
        }

        Spacer()

        Button(model.showCompletedInSearchResults ? String(localized: "hide", bundle: .main) : String(localized: "show", bundle: .main)) {
          Task { await model.showCompletedButtonTapped() }
        }
      }
    }
    .buttonStyle(.borderless)

    ForEach(model.reminders) { reminder in
      ReminderRow(
        color: reminder.remindersList.color,
        isPastDue: reminder.isPastDue,
        notes: reminder.notes,
        reminder: reminder.reminder,
        remindersList: reminder.remindersList,
        showCompleted: model.showCompletedInSearchResults
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
        SearchRemindersView(model: SearchRemindersModel())
      } else {
        Text(String(localized: "tap_search", bundle: .main))
      }
    }
    .searchable(text: $searchText)
  }
}
