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
    HStack {
      Image(systemName: "list.bullet")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: DesignConstants.frameHeightSmall)
        .foregroundStyle(remindersList.color)
        .padding(.leading, DesignConstants.paddingLarge)

      Text(remindersList.title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

      Spacer()

      Text("\(remindersCount)")
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .padding(.trailing, DesignConstants.paddingLarge)
    }
    .frame(height: DesignConstants.frameHeightXXLarge)
    .background {
      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
        .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)

//      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
//        .inset(by: DesignConstants.lineWidthThin)
//        .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(DesignConstants.opacityMedium), lineWidth: DesignConstants.lineWidthThin)
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
          .frame(height: DesignConstants.frameHeightSmall)
      }
      .tint(ResourcesAsset.Colors.energy.swiftUIColor)

      Button {
        editList = remindersList
      } label: {
        Image(systemName: "info.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameHeightSmall)
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

