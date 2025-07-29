import IssueReporting
import SharingGRDB
import SwiftUI
import Common
import Resources

struct RemindersListForm: View {
  @Dependency(\.defaultDatabase) private var database
  
  @State var remindersList: RemindersList.Draft
  @Environment(\.dismiss) var dismiss
  
  init(remindersList: RemindersList.Draft) {
    self.remindersList = remindersList
  }
  
  var body: some View {
    ListFormView(
      list: $remindersList,
      title: $remindersList.title,
      color: $remindersList.color
    ) { list in
      withErrorReporting {
        try database.write { db in
          try RemindersList.upsert(list)
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
      RemindersListForm(remindersList: RemindersList.Draft())
        .navigationTitle(String(localized: "new_list", bundle: .main))
    }
  }
}
