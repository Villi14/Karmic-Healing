import SharingGRDB
import SwiftUI
import Resources

struct RemindersListRow: View {
  let remindersCount: Int
  let remindersList: RemindersList
  var onTap: (() -> Void)? = nil

  @State var editList: RemindersList?

  @Dependency(\.defaultDatabase) private var database

  var body: some View {
    HStack {
      Image(systemName: "list.bullet")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: 18)
        .foregroundStyle(remindersList.color)
        .padding(.leading, 16)

      Text(remindersList.title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

      Spacer()

      Text("\(remindersCount)")
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .padding(.trailing, 16)
    }
    .frame(height: 56)
    .background {
      RoundedRectangle(cornerRadius: 12)
        .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)

      RoundedRectangle(cornerRadius: 12)
        .inset(by: 0.5)
        .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.5), lineWidth: 0.5)
    }
    .swipeActions {
      Button {
        withErrorReporting {
          try database.write { db in
            try RemindersList.delete(remindersList)
              .execute(db)
          }
        }
      } label: {
        Image(systemName: "trash")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 18)
      }
      .tint(ResourcesAsset.Colors.energy.swiftUIColor)

      Button {
        editList = remindersList
      } label: {
        Image(systemName: "info.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: 18)
      }
      .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
    }
    .sheet(item: $editList) { list in
      NavigationStack {
        RemindersListForm(remindersList: RemindersList.Draft(list))
          .navigationTitle(String(localized: "edit_list", bundle: .main))
      }
      .presentationDetents([.medium])
    }
    .contentShape(Rectangle())
    .onTapGesture {
      onTap?()
    }
  }
}

struct RemindersListRowPreview: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      List {
        RemindersListRow(
          remindersCount: 10,
          remindersList: RemindersList(
            id: UUID(),
            color: ResourcesAsset.Colors.clam.swiftUIColor,
            title: String(localized: "personal", bundle: .main)
          )
        )
      }
    }
  }
}
