import SharingGRDB
import SwiftUI
import Common
import Resources

struct ReminderRow: View {
  let color: Color
  let isPastDue: Bool
  let notes: String
  let reminder: Reminder
  let remindersList: RemindersList
  let showCompleted: Bool

  @State var editReminder: Reminder.Draft?
  @State var isCompleted: Bool

  @Dependency(\.defaultDatabase) private var database

  init(
    color: Color,
    isPastDue: Bool,
    notes: String,
    reminder: Reminder,
    remindersList: RemindersList,
    showCompleted: Bool,
  ) {
    self.color = color
    self.isPastDue = isPastDue
    self.notes = notes
    self.reminder = reminder
    self.remindersList = remindersList
    self.showCompleted = showCompleted
    self.isCompleted = reminder.isCompleted
  }

  var body: some View {
    ItemRowView(
      editItem: $editReminder,
      color: color,
      isPastDue: isPastDue,
      notes: notes,
      item: reminder,
      list: remindersList,
      showCompleted: showCompleted,
      isCompleted: reminder.isCompleted,
      isFlagged: reminder.isFlagged,
      title: reminder.title,
      priority: reminder.priority,
      listColor: remindersList.color,
      onComplete: completeButtonTapped,
      onToggleCompletion: toggleCompletion,
      onDelete: {
        withErrorReporting {
          try database.write { db in
            try Reminder.delete(reminder).execute(db)
          }
        }
      },
      onToggleFlag: {
        withErrorReporting {
          try database.write { db in
            try Reminder
              .find(reminder.id)
              .update { $0.isFlagged.toggle() }
              .execute(db)
          }
        }
      },
      onEdit: {
        editReminder = Reminder.Draft(reminder)
      },
      onShowDetails: {
        editReminder = Reminder.Draft(reminder)
      },
      formView: { reminder, remindersList in
        AnyView(ReminderFormView(reminder: reminder, remindersList: remindersList))
      }
    )
  }

  private func completeButtonTapped() {
    if showCompleted {
      toggleCompletion()
    } else {
      isCompleted.toggle()
    }
  }

  private func toggleCompletion() {
    withErrorReporting {
      try database.write { db in
        isCompleted =
        try Reminder
          .find(reminder.id)
          .update { $0.isCompleted.toggle() }
          .returning(\.isCompleted)
          .fetchOne(db) ?? isCompleted
      }
    }
  }
}

struct ReminderRowPreview: PreviewProvider {
  static var previews: some View {
    var reminder: Reminder!
    var remindersList: RemindersList!
    let _ = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      try $0.defaultDatabase.read { db in
        reminder = try Reminder.all.fetchOne(db)
        remindersList = try RemindersList.all.fetchOne(db)!
      }
    }

    NavigationStack {
      List {
        ReminderRow(
          color: remindersList.color,
          isPastDue: false,
          notes: reminder.notes.replacingOccurrences(of: "\n", with: " "),
          reminder: reminder,
          remindersList: remindersList,
          showCompleted: true
        )
      }
    }
  }
}
