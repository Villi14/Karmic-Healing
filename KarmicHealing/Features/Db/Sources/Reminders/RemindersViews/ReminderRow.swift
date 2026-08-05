import SQLiteData
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
  /// Screens that mix topics — Today, All, search — name the topic each reminder came from.
  /// A topic's own screen already says it in the title, so it stays quiet there.
  let showsTopic: Bool

  @State var editReminder: Reminder.Draft?
  @State var isCompleted: Bool

  @Dependency(\.defaultDatabase) private var database
  @Dependency(\.continuousClock) private var clock

  init(
    color: Color,
    isPastDue: Bool,
    notes: String,
    reminder: Reminder,
    remindersList: RemindersList,
    showCompleted: Bool,
    showsTopic: Bool = false,
  ) {
    self.color = color
    self.isPastDue = isPastDue
    self.notes = notes
    self.reminder = reminder
    self.remindersList = remindersList
    self.showCompleted = showCompleted
    self.showsTopic = showsTopic
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
            .foregroundStyle(AuraGradient.gradient(for: color))
            .padding([.trailing], DesignConstants.paddingSmall)
            .animation(Motion.touch, value: isCompleted)
        }
        
        VStack(alignment: .leading) {
          if showsTopic {
            RowBadge(
              title: remindersList.title,
              tone: remindersList.color,
              iconName: "tag.fill"
            )
          }
          HStack(alignment: .firstTextBaseline) {
            if let priority = reminder.priority {
              Text(String(repeating: "!", count: priority.rawValue))
                .foregroundStyle(isCompleted ? ResourcesAsset.Colors.textSecondary.swiftUIColor : remindersList.color)
            }
            Text(reminder.title)
              .strikethrough(isCompleted, pattern: .solid, color: ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .foregroundStyle(
                isCompleted ? ResourcesAsset.Colors.textSecondary.swiftUIColor : ResourcesAsset.Colors.textPrimary.swiftUIColor
              )
          }
          .font(Typography.listTitle)
          if !notes.isEmpty {
            Text(notes)
              .font(Typography.bodySecondary)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .lineLimit(2)
          }
          if let dueDate = reminder.dueDate {
            DueDateBadge(date: dueDate, isPastDue: isPastDue && !isCompleted, level: .solar)
          }
        }
      }
      
      Spacer()
      
      if reminder.isFlagged {
        Image(systemName: "flag.fill")
          .font(Typography.body)
          .foregroundStyle(AuraGradient.gradient(for: color))
      }

      // A topic row carries its info button in plain sight, so a reminder carries one too —
      // editing a reminder should not be a thing you have to discover by swiping.
      Button(action: editButtonTapped) {
        Image(systemName: "info.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameHeightSmall)
          .foregroundStyle(AuraGradient.gradient(for: color))
          .padding(.leading, DesignConstants.paddingSmall)
      }
    }
    .padding(.horizontal, DesignConstants.paddingLarge)
    .padding(.vertical, DesignConstants.paddingMedium)
    .cardStyle(
      tone: color,
      elevation: .flat,
      gradient: AuraGradient.gradient(for: color)
    )
    .buttonStyle(.borderless)
    .rowSwipeActions(
      onDelete: deleteReminder,
      onEdit: editButtonTapped,
      flag: FlagAction(isFlagged: reminder.isFlagged, toggle: toggleFlag)
    )
    .sheet(item: $editReminder) { item in
      NavigationStack {
        ReminderFormView(reminder: item, remindersList: remindersList, title: "details".loc)
      }
    }
    .task(id: isCompleted) {
      guard !showCompleted else { return }
      guard isCompleted, isCompleted != reminder.isCompleted else { return }
      do {
        try await clock.sleep(for: .seconds(2))
        toggleCompletion()
      } catch {}
    }
  }
  
  private func editButtonTapped() {
    editReminder = Reminder.Draft(reminder)
  }

  private func toggleFlag() {
    withErrorReporting {
      try database.write { db in
        try Reminder
          .find(reminder.id)
          .update { $0.isFlagged.toggle() }
          .execute(db)
      }
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
        try Reminder
          .find(reminder.id)
          .update { $0.isCompleted.toggle() }
          .execute(db)
        isCompleted = try Reminder
          .find(reminder.id)
          .select { $0.isCompleted }
          .fetchOne(db) ?? isCompleted
      }
    }
  }
  
  private func deleteReminder() {
    withErrorReporting {
      try database.write { db in
        try Reminder.delete(reminder).execute(db)
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
