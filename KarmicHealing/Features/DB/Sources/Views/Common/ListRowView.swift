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

  @State private var allRequestsCompleted: Bool = false
  @State private var totalRequests: Int = 0
  @State private var completedRequests: Int = 0

  @Dependency(\.defaultDatabase) private var database

  var body: some View {
    HStack {
      if let requestsList = list as? RequestsList {
        Button(action: {
          Task {
            if canToggle {
              try? await toggleRequestsListCompletion(requestsList)
              await fetchRequestsStatus(requestsList)
            }
          }
        }) {
          Image(systemName: requestsList.isCompleted ? "circle.inset.filled" : "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(color)
            .padding(.leading, DesignConstants.paddingLarge)
        }
        .disabled(!canToggle)
        .onAppear {
          Task { await fetchRequestsStatus(requestsList) }
        }
        .padding(.trailing, 0)
      } else {
        Image(systemName: "list.bullet")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameHeightSmall)
          .foregroundStyle(color)
          .padding(.leading, DesignConstants.paddingLarge)
      }
      Text(title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .font(.headline.weight(.medium))
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

  private var canToggle: Bool {
    (totalRequests == 0 || allRequestsCompleted)
  }

  private func fetchRequestsStatus(_ requestsList: RequestsList) async {
    await withErrorReporting {
      let (total, completed) = try await database.read { db in
        let total = try Request.where { $0.requestsListID == requestsList.id }.fetchCount(db)
        let completed = try Request.where { $0.requestsListID == requestsList.id && $0.isCompleted }.fetchCount(db)
        return (total, completed)
      }
      totalRequests = total
      completedRequests = completed
      allRequestsCompleted = (total > 0 && total == completed)
    }
  }

  private func toggleRequestsListCompletion(_ requestsList: RequestsList) async throws {
    try await database.write { db in
      let newCompletionStatus = !requestsList.isCompleted
      try RequestsList
        .find(requestsList.id)
        .update { $0.isCompleted = newCompletionStatus }
        .execute(db)
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
