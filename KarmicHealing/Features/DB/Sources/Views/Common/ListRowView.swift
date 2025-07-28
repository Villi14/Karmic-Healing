import SharingGRDB
import SwiftUI
import Common
import Resources

struct ListRowView<ListType: Identifiable>: View {
  let count: Int
  let list: ListType
  let color: Color
  let title: String
  var onTap: (() -> Void)? = nil
  var onDelete: (() -> Void)? = nil
  var onEdit: (() -> Void)? = nil

  @Dependency(\.defaultDatabase) private var database

  var body: some View {
    HStack {
      Image(systemName: "list.bullet")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(height: DesignConstants.frameHeightSmall)
        .foregroundStyle(color)
        .padding(.leading, DesignConstants.paddingLarge)

      Text(title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

      Spacer()

      Text("\(count)")
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .padding(.trailing, DesignConstants.paddingLarge)
    }
    .frame(height: DesignConstants.frameHeightXXLarge)
    .background {
      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
        .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
    }
    .swipeActions {
      if let onDelete = onDelete {
        Button {
          onDelete()
        } label: {
          Image(systemName: "trash")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
        }
        .tint(ResourcesAsset.Colors.energy.swiftUIColor)
      }

      if let onEdit = onEdit {
        Button {
          onEdit()
        } label: {
          Image(systemName: "info.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
        }
        .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
      }
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
      ListRowView(
        count: 10,
        list: RequestsList(id: UUID(), title: "Personal"),
        color: .blue,
        title: "Personal"
      )
    }
  }
} 
