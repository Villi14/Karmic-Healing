import IssueReporting
import SharingGRDB
import SwiftUI
import Resources

struct ReminderFormView: View {
  @FetchAll(RemindersList.order(by: \.title)) var remindersLists
  @FetchOne var remindersList: RemindersList

  @State var reminder: Reminder.Draft

  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss

  init(reminder: Reminder.Draft, remindersList: RemindersList) {
    _remindersList = FetchOne(wrappedValue: remindersList, RemindersList.find(remindersList.id))
    self.reminder = reminder
  }

  var body: some View {
    Form {
      TextField(String(localized: "title", bundle: .main), text: $reminder.title)

      ZStack {
        if reminder.notes.isEmpty {
          TextEditor(text: .constant(String(localized: "notes", bundle: .main)))
            .foregroundStyle(.placeholder)
            .accessibilityHidden(true, isEnabled: false)
        }

        TextEditor(text: $reminder.notes)
      }
      .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      .tint(ResourcesAsset.Colors.clam.swiftUIColor)
      .lineLimit(4)
      .padding(.horizontal, -5)

      Section {
        Toggle(isOn: $reminder.isDateSet.animation()) {
          HStack {
            Image(systemName: "calendar")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 18, height: 18)
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text(String(localized: "date", bundle: .main))
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)

        if let dueDate = reminder.dueDate {
          DatePicker(
            "",
            selection: $reminder.dueDate[coalesce: dueDate],
            displayedComponents: [.date, .hourAndMinute]
          )
          .tint(ResourcesAsset.Colors.clam.swiftUIColor)
          .padding(.vertical, 2)
        }
      }

      Section {
        Toggle(isOn: $reminder.isFlagged) {
          HStack {
            Image(systemName: "flag")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 18, height: 18)
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
            Text(String(localized: "flag", bundle: .main))
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)

        Picker(selection: $reminder.priority) {
          Text(String(localized: "none", bundle: .main)).tag(Priority?.none)
          Divider()
          Text(String(localized: "high", bundle: .main)).tag(Priority.high)
          Text(String(localized: "medium", bundle: .main)).tag(Priority.medium)
          Text(String(localized: "low", bundle: .main)).tag(Priority.low)
        } label: {
          HStack {
            Image(systemName: "exclamationmark")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 18, height: 18)
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text(String(localized: "priority", bundle: .main))
          }
        }

        Picker(selection: $reminder.remindersListID) {
          ForEach(remindersLists) { remindersList in
            Text(remindersList.title)
              .tag(remindersList)
              .buttonStyle(.plain)
              .tag(remindersList.id)
          }
        } label: {
          HStack {
            Image(systemName: "list.bullet")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 18, height: 18)
              .foregroundStyle(remindersList.color)
            Text(String(localized: "list", bundle: .main))
          }
        }
        .task(id: reminder.remindersListID) {
          await withErrorReporting {
            try await $remindersList.load(RemindersList.find(reminder.remindersListID))
          }
        }
      }
    }
    .padding(.top, -28)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button(action: saveButtonTapped) {
          Text(String(localized: "save", bundle: .main))
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button(String(localized: "cancel", bundle: .main)) {
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      }
    }
  }

  private func saveButtonTapped() {
    withErrorReporting {
      try database.write { db in
        let reminder = reminder
        try Reminder.upsert(reminder).returning(\.id).fetchOne(db)!
      }
    }
    dismiss()
  }
}

extension Reminder.Draft {
  fileprivate var isDateSet: Bool {
    get { dueDate != nil }
    set { dueDate = newValue ? Date() : nil }
  }
}

extension Optional {
  fileprivate subscript(coalesce coalesce: Wrapped) -> Wrapped {
    get { self ?? coalesce }
    set { self = newValue }
  }
}

struct ReminderFormPreview: PreviewProvider {
  static var previews: some View {
    let (remindersList, reminder) = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      return try $0.defaultDatabase.write { db in
        let remindersList = try RemindersList.all.fetchOne(db)!
        return (
          remindersList,
          try Reminder.where { $0.remindersListID == remindersList.id }.fetchOne(db)!
        )
      }
    }
    
    NavigationStack {
      ReminderFormView(reminder: Reminder.Draft(reminder), remindersList: remindersList)
        .navigationTitle(String(localized: "detail", bundle: .main))
    }
  }
}
