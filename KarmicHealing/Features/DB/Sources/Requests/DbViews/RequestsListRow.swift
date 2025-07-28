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
    ListRowView(
      count: requestsCount,
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
    .sheet(item: $editList) { list in
      NavigationStack {
        RequestsListForm(requestsList: RequestsList.Draft(list))
          .navigationTitle(String(localized: "edit_list", bundle: .main))
      }
      .presentationDetents([.medium])
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

