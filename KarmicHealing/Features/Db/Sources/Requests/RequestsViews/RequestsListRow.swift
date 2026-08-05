import SQLiteData
import SwiftUI
import Common

struct RequestsListRow: View {
  let requestsList: RequestsList
  var onTap: (() -> Void)? = nil

  @State var editList: RequestsList?

  /// Watched rather than counted once, so the radio button unlocks the moment the last
  /// subrequest is fulfilled.
  @FetchAll var subrequests: [Request]

  @Dependency(\.defaultDatabase) private var database

  init(requestsList: RequestsList, onTap: (() -> Void)? = nil) {
    self.requestsList = requestsList
    self.onTap = onTap
    _subrequests = FetchAll(
      Request.where { $0.requestsListID.eq(requestsList.id) },
      animation: .default
    )
  }

  var body: some View {
    ListRowView(
      count: subrequests.count,
      color: requestsList.color,
      title: requestsList.title,
      completion: ListRowView.Completion(
        isCompleted: requestsList.isCompleted,
        isEnabled: RequestsList.canToggleCompletion(requestsList, progress: progress),
        toggle: toggleCompletion
      ),
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
    .sheet(item: $editList) { list in
      NavigationStack {
        RequestsListForm(
          requestsList: RequestsList.Draft(list),
          title: "request_placeholder".loc
        )
      }
      .presentationDetents([.large])
    }
  }

  private var progress: SubrequestProgress {
    SubrequestProgress(
      total: subrequests.count,
      completed: subrequests.filter(\.isCompleted).count
    )
  }

  private func toggleCompletion() {
    withErrorReporting {
      try database.write { db in
        try RequestsList.toggleCompletion(of: requestsList.id, in: db)
      }
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
