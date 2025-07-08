import IssueReporting
import SharingGRDB
import SwiftUI
import Resources

struct RemindersListForm: View {
  @Dependency(\.defaultDatabase) private var database
  
  @State var remindersList: RemindersList.Draft
  @Environment(\.dismiss) var dismiss
  
  init(remindersList: RemindersList.Draft) {
    self.remindersList = remindersList
  }
  
  var body: some View {
    Form {
      Section {
        VStack {
          TextField(String(localized: "list_name", bundle: .main), text: $remindersList.title)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(remindersList.color)
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .tint(ResourcesAsset.Colors.clam.swiftUIColor)
            .padding(.horizontal, 32)
            .padding(.vertical)
        }
      }

      ColorPicker(String(localized: "color", bundle: .main), selection: $remindersList.color)
        .tint(ResourcesAsset.Colors.clam.swiftUIColor)
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button(String(localized: "save", bundle: .main)) {
          withErrorReporting {
            try database.write { db in
              try RemindersList.upsert(remindersList)
                .execute(db)
            }
          }
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        .disabled(remindersList.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button(String(localized: "cancel", bundle: .main)) {
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
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
