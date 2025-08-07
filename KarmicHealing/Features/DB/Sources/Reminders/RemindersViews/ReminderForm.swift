import IssueReporting
import SharingGRDB
import SwiftUI
import Common
import Resources

struct ReminderFormView: View {
  @Dependency(\.notification) var notification

  @FetchAll(RemindersList.order(by: \.title)) var remindersLists
  @FetchOne var remindersList: RemindersList

  @State var reminder: Reminder.Draft
  @State private var selectedDate: Date = {
    // Set current local time as initial value
    let now = Date()
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
    return calendar.date(from: components) ?? now
  }()
  @State private var showDateErrorAlert = false

  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss

  init(reminder: Reminder.Draft, remindersList: RemindersList) {
    _remindersList = FetchOne(wrappedValue: remindersList, RemindersList.find(remindersList.id))
    self.reminder = reminder

    if let dueDate = reminder.dueDate {
      self._selectedDate = State(initialValue: dueDate)
    }
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
      .padding(.horizontal, DesignConstants.paddingNegativeSmall)

      Section {
        Toggle(isOn: $reminder.isDateSet.animation()) {
          HStack {
            Image(systemName: "calendar")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text(String(localized: "date", bundle: .main))
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)
        .onChange(of: reminder.isDateSet) { _, isSet in
          if isSet {
            reminder.dueDate = selectedDate
          } else {
            reminder.dueDate = nil
          }
        }

        if let dueDate = reminder.dueDate {
          DatePicker(
            "",
            selection: $selectedDate,
            displayedComponents: [.date, .hourAndMinute]
          )
          .tint(ResourcesAsset.Colors.clam.swiftUIColor)
          .padding(.vertical, DesignConstants.paddingTiny)
          .onChange(of: selectedDate) { _, newDate in
            reminder.dueDate = newDate

            // Log date change
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            formatter.timeZone = TimeZone.current

            print("ReminderForm: DatePicker changed")
            print("ReminderForm: New date (UTC): \(newDate)")
            print("ReminderForm: New date (local): \(formatter.string(from: newDate))")
          }
        }
      }

      Section {
        // Видалено Toggle(isOn: $reminder.isFlagged)
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
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text(String(localized: "priority", bundle: .main))
          }
        }

        Picker(selection: $reminder.remindersListID) {
          ForEach(remindersLists) { remindersList in
            Text(remindersList.title)
              .buttonStyle(.plain)
              .tag(remindersList.id)
          }
        } label: {
          HStack {
            Image(systemName: "list.bullet")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
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
    .padding(.top, DesignConstants.paddingNegativeXLarge)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button(action: saveButtonTapped) {
          Text(String(localized: "save", bundle: .main))
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        .disabled(reminder.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }

      ToolbarItem(placement: .cancellationAction) {
        Button(String(localized: "cancel", bundle: .main)) {
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      }
    }
    .sheet(isPresented: $showDateErrorAlert) {
      AlertView<Never>(
        store: .init(
          initialState: .error(
            title: String(localized: "date_error", bundle: .main),
            message: String(localized: "date_error_message", bundle: .main)
          ),
          reducer: { AlertReducer() }
        )
      )
    }
  }

  private func saveButtonTapped() {
    // Check date before saving
    if let dueDate = reminder.dueDate {
      let timeInterval = dueDate.timeIntervalSinceNow

      // Check if date is in the future
      guard timeInterval > 0 else {
        showDateErrorAlert = true
        return // Don't save and don't close the screen
      }
    }

    // Save reminder only if date is valid
    withErrorReporting {
      let reminderID = try database.write { db in
        try Reminder.upsert(reminder).returning(\.id).fetchOne(db)!
      }

      if let dueDate = reminder.dueDate {
        let timeInterval = dueDate.timeIntervalSinceNow

        Task {
          notification.scheduleReminderNotificationWithIntent(
            reminder.title,
            reminder.notes.isEmpty ? "" : reminder.notes,
            timeInterval,
            reminderID,
            remindersList.id,
            .reminder
          )
        }
      }
    }

    // Close screen only after successful save
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
