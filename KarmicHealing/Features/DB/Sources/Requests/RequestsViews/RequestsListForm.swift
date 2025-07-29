import IssueReporting
import SharingGRDB
import SwiftUI
import Common
import Resources

struct RequestsListForm: View {
  @Dependency(\.defaultDatabase) private var database
  
  @State var requestsList: RequestsList.Draft
  @Environment(\.dismiss) var dismiss
  
  init(requestsList: RequestsList.Draft) {
    self.requestsList = requestsList
  }
  
  var body: some View {
    ListFormView(
      list: $requestsList,
      title: $requestsList.title,
      color: $requestsList.color
    ) { list in
      withErrorReporting {
        try database.write { db in
          try RequestsList.upsert(list)
            .execute(db)
        }
      }
    }
  }
}

struct RequestsListFormPreviews: PreviewProvider {
  static var previews: some View {
    let _ = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
    }
    
    NavigationStack {
      RequestsListForm(requestsList: RequestsList.Draft())
        .navigationTitle(String(localized: "new_list", bundle: .main))
    }
  }
}
