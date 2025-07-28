import SharingGRDB
import SwiftUI
import Common
import Resources

struct RemindersListRow: View {
  let remindersCount: Int
  let remindersList: RemindersList
  var onTap: (() -> Void)? = nil

  @State var editList: RemindersList?

  @Dependency(\.defaultDatabase) private var database

  var body: some View {
    ListRowView(
      count: remindersCount,
      list: remindersList,
      color: remindersList.color,
      title: remindersList.title,
      onTap: onTap,
      onDelete: {
        withErrorReporting {
          try database.write { db in
            try RemindersList.delete(remindersList)
              .execute(db)
          }
        }
      },
      onEdit: {
        editList = remindersList
      }
    )
    .sheet(item: $editList) { list in
      NavigationStack {
        RemindersListForm(remindersList: RemindersList.Draft(list))
          .navigationTitle(String(localized: "edit_list", bundle: .main))
      }
      .presentationDetents([.medium])
    }
  }
}

#Preview {
  NavigationStack {
    List {
      RemindersListRow(
        remindersCount: 10,
        remindersList: RemindersList(
          id: UUID(),
          title: "Personal"
        )
      )
    }
  }
}

