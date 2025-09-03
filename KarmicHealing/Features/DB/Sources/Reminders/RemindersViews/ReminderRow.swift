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
    HStack {
      HStack(alignment: .firstTextBaseline) {
        Button(action: completeButtonTapped) {
          Image(systemName: isCompleted ? "circle.inset.filled" : "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)
            .padding([.trailing], DesignConstants.paddingSmall)
        }
        
        VStack(alignment: .leading) {
          HStack(alignment: .firstTextBaseline) {
            if let priority = reminder.priority {
              Text(String(repeating: "!", count: priority.rawValue))
                .foregroundStyle(isCompleted ? ResourcesAsset.Colors.textSecondary.swiftUIColor : remindersList.color)
            }
            Text(reminder.title)
              .foregroundStyle(
                isCompleted ? ResourcesAsset.Colors.textSecondary.swiftUIColor : ResourcesAsset.Colors.textPrimary.swiftUIColor
              )
          }
          .font(.title3)
          if !notes.isEmpty {
            Text(notes)
              .font(.subheadline)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .lineLimit(2)
          }
        }
      }
      
      Spacer()
      
      if !isCompleted {
        HStack {
          if reminder.isFlagged {
            Image(systemName: "flag")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
          }
          Button {
            editReminder = Reminder.Draft(reminder)
          } label: {
            Image(systemName: "info.circle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.clarity.swiftUIColor)
          }
          .tint(color)
        }
      }
    }
    .buttonStyle(.borderless)
    .swipeActions {
      Button("delete".loc(), role: .destructive) {
        withErrorReporting {
          try database.write { db in
            try Reminder.delete(reminder).execute(db)
          }
        }
      }
      .tint(ResourcesAsset.Colors.energy.swiftUIColor)
      Button(reminder.isFlagged ? "unflag".loc() : "flag".loc()) {
        withErrorReporting {
          try database.write { db in
            try Reminder
              .find(reminder.id)
              .update { $0.isFlagged.toggle() }
              .execute(db)
          }
        }
      }
      .tint(ResourcesAsset.Colors.friendly.swiftUIColor)
      Button("details".loc()) {
        editReminder = Reminder.Draft(reminder)
      }
      .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
    }
    .sheet(item: $editReminder) { item in
      NavigationStack {
        ReminderFormView(reminder: item, remindersList: remindersList)
          .navigationTitle("details".loc())
      }
    }
    .task(id: isCompleted) {
      guard !showCompleted else { return }
      guard isCompleted, isCompleted != reminder.isCompleted else { return }
      do {
        try await Task.sleep(for: .seconds(2))
        toggleCompletion()
      } catch {}
    }
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
