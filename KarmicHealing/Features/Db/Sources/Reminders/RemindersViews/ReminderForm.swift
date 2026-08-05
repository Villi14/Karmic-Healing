import IssueReporting
import SQLiteData
import SwiftUI
import Common
import Resources

struct ReminderFormView: View {
  @Dependency(\.notification) var notification
  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss
  
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
  
  let title: String

  init(reminder: Reminder.Draft, remindersList: RemindersList, title: String) {
    _remindersList = FetchOne(wrappedValue: remindersList, RemindersList.find(remindersList.id))
    self.reminder = reminder
    self.title = title


    if let dueDate = reminder.dueDate {
      self._selectedDate = State(initialValue: dueDate)
    }
  }
  
  var body: some View {
    Form {
      TextField("title".loc, text: $reminder.title, axis: .vertical)
        .font(Typography.title)
        .tint(Spectrum.solar.color)

      TextField("notes".loc, text: $reminder.notes, axis: .vertical)
        .lineLimit(DesignConstants.notesLineLimit...)
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .tint(Spectrum.solar.color)
      
      Section {
        Toggle(isOn: $reminder.isDateSet.animation()) {
          HStack {
            Image(systemName: "calendar")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(AuraGradient.gradient(for: .solar))
            Text("date".loc)
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
        
        if reminder.dueDate != nil {
          DatePicker(
            "",
            selection: $selectedDate,
            displayedComponents: [.date, .hourAndMinute]
          )
          .tint(Spectrum.solar.color)
          .padding(.vertical, DesignConstants.paddingTiny)
          .onChange(of: selectedDate) { _, newDate in
            reminder.dueDate = newDate
            
            // Log date change
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            formatter.timeZone = TimeZone.current
          }
        }
      }
      
      Section {
        Toggle(isOn: $reminder.isFlagged) {
          HStack {
            Image(systemName: "flag")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(AuraGradient.gradient(for: .solar))
            Text("flag".loc)
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)
        
        Picker(selection: $reminder.priority) {
          Text("none".loc).tag(Priority?.none)
          Divider()
          Text("high".loc).tag(Priority.high)
          Text("medium".loc).tag(Priority.medium)
          Text("low".loc).tag(Priority.low)
        } label: {
          HStack {
            Image(systemName: "exclamationmark")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(AuraGradient.gradient(for: .solar))
            Text("priority".loc)
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
            Image(systemName: "tag")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(remindersList.color)
            Text("list".loc)
          }
        }
        .task(id: reminder.remindersListID) {
          _ = await withErrorReporting {
            try await $remindersList.load(RemindersList.find(reminder.remindersListID))
          }
        }
      }
    }
    .padding(.top, DesignConstants.paddingNegativeXLarge)
    .scrollContentBackground(.hidden)
    .karmicFormTitle(title)
    .background { AuraBackground(level: .solar) }
    .toolbar {
      ToolbarItem {
        Button(action: saveButtonTapped) {
          Text("save".loc)
        }
        .foregroundStyle(AuraGradient.gradient(for: .solar))
        .disabled(reminder.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button("cancel".loc) {
          dismiss()
        }
        .foregroundStyle(AuraGradient.gradient(for: .solar))
      }
    }
    .alert("date_error".loc, isPresented: $showDateErrorAlert) {
      Button("done".loc) { }
    } message: {
      Text("date_error_message".loc)
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
        try Reminder.upsert { reminder }.returning(\.id).fetchOne(db)!
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
          try Reminder.where { $0.remindersListID.eq(remindersList.id) }.fetchOne(db)!
        )
      }
    }
    
    NavigationStack {
      ReminderFormView(
        reminder: Reminder.Draft(reminder),
        remindersList: remindersList,
        title: "detail".loc
      )
    }
  }
}
