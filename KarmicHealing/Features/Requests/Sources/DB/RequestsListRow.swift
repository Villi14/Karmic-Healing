import SharingGRDB
import SwiftUI
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
        .frame(height: 18)
        .foregroundStyle(requestsList.color)
        .padding(.leading, 16)

      Text(requestsList.title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

      Spacer()

      Text("\(requestsCount)")
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
            try RequestsList.delete(requestsList)
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
        editList = requestsList
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

struct RequestsListRowPreview: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      List {
        RequestsListRow(
          requestsCount: 10,
          requestsList: RequestsList(
            id: UUID(),
            color: ResourcesAsset.Colors.clam.swiftUIColor,
            title: String(localized: "personal", bundle: .main)
          )
        )
      }
    }
  }
}
