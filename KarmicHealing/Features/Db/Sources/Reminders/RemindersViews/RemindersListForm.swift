import IssueReporting
import SQLiteData
import SwiftUI
import Common

struct RemindersListForm: View {
  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss

  @State var remindersList: RemindersList.Draft

  let title: String

  init(remindersList: RemindersList.Draft, title: String) {
    self.remindersList = remindersList
    self.title = title
  }

  var body: some View {
    ListFormView(
      list: $remindersList,
      title: $remindersList.title,
      color: $remindersList.color,
      screenTitle: title
    ) { list in
      withErrorReporting {
        try database.write { db in
          try RemindersList.upsert { list }
            .execute(db)
        }
      }
    }
  }
}

struct RemindersListFormPreviews: PreviewProvider {
  static var previews: some View {
    let _ = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
    }

    NavigationStack {
      RemindersListForm(remindersList: RemindersList.Draft(), title: "new_list".loc)
    }
  }
}
