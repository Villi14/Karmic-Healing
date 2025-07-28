import SharingGRDB
import SwiftUI
import Common
import Resources

struct RequestsListRow: View {
  let requestsCount: Int
  let requestsList: RequestsList
  var onTap: (() -> Void)? = nil

  @State var editList: RequestsList?

  @Dependency(\.defaultDatabase) private var database

  var body: some View {
    HStack {
      Image(systemName: "list.bullet")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: DesignConstants.frameHeightSmall)
        .foregroundStyle(requestsList.color)
        .padding(.leading, DesignConstants.paddingLarge)

      Text(requestsList.title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

      Spacer()

      Text("\(requestsCount)")
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
            try RequestsList.delete(requestsList)
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
        editList = requestsList
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
        RequestsListForm(requestsList: RequestsList.Draft(list))
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
      RequestsListRow(
        requestsCount: 10,
        requestsList: RequestsList(
          id: UUID(),
          title: "Personal"
        )
      )
    }
  }
}

