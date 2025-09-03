import SharingGRDB
import SwiftUI
import Common
import Resources

struct RequestsListRow: View {
  let requestsList: RequestsList
  var onTap: (() -> Void)? = nil
  
  @State var editList: RequestsList?
  @State private var allRequestsCompleted: Bool = false
  @State private var totalRequests: Int = 0
  @State private var completedRequests: Int = 0
  
  @Dependency(\.defaultDatabase) private var database
  
  var body: some View {
    ListRowView(
      count: totalRequests,
      list: requestsList,
      color: requestsList.color,
      title: requestsList.title,
      onTap: onTap,
      onDelete: {
        withErrorReporting {
          try database.write { db in
            try RequestsList.delete(requestsList)
              .execute(db)
          }
        }
      },
      onEdit: {
        editList = requestsList
      }
    )
    .onAppear {
      Task { await fetchRequestsStatus() }
    }
    .sheet(item: $editList) { list in
      NavigationStack {
        RequestsListForm(requestsList: RequestsList.Draft(list))
          .navigationTitle("edit_list".loc())
      }
      .presentationDetents([.large])
    }
  }
  
  private func fetchRequestsStatus() async {
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
}

#Preview {
  NavigationStack {
    List {
      RequestsListRow(
        requestsList: RequestsList(
          id: UUID(),
          title: "Personal"
        )
      )
    }
  }
}

