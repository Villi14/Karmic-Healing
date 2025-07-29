import SharingGRDB
import SwiftUI
import Common
import Resources

struct RequestRow: View {
  let color: Color
  let isPastDue: Bool
  let notes: String
  let request: Request
  let requestsList: RequestsList
  let showCompleted: Bool

  @State var editRequest: Request.Draft?
  @State var isCompleted: Bool

  @Dependency(\.defaultDatabase) private var database

  init(
    color: Color,
    isPastDue: Bool,
    notes: String,
    request: Request,
    requestsList: RequestsList,
    showCompleted: Bool,
  ) {
    self.color = color
    self.isPastDue = isPastDue
    self.notes = notes
    self.request = request
    self.requestsList = requestsList
    self.showCompleted = showCompleted
    self.isCompleted = request.isCompleted
  }

  var body: some View {
    ItemRowView(
      editItem: $editRequest,
      color: color,
      isPastDue: isPastDue,
      notes: notes,
      item: request,
      list: requestsList,
      showCompleted: showCompleted,
      isCompleted: request.isCompleted,
      isFlagged: request.isFlagged,
      title: request.title,
      priority: request.priority,
      listColor: requestsList.color,
      onComplete: completeButtonTapped,
      onToggleCompletion: toggleCompletion,
      onDelete: {
        withErrorReporting {
          try database.write { db in
            try Request.delete(request).execute(db)
          }
        }
      },
      onToggleFlag: {
        withErrorReporting {
          try database.write { db in
            try Request
              .find(request.id)
              .update { $0.isFlagged.toggle() }
              .execute(db)
          }
        }
      },
      onEdit: {
        editRequest = Request.Draft(request)
      },
      onShowDetails: {
        editRequest = Request.Draft(request)
      },
      formView: { request, requestsList in
        AnyView(RequestFormView(request: request, requestsList: requestsList))
      }
    )
  }

  private func completeButtonTapped() {
    if showCompleted {
      toggleCompletion()
    } else {
      isCompleted.toggle()
    }
  }

  private func toggleCompletion() {
    withErrorReporting {
      try database.write { db in
        isCompleted =
        try Request
          .find(request.id)
          .update { $0.isCompleted.toggle() }
          .returning(\.isCompleted)
          .fetchOne(db) ?? isCompleted
      }
    }
  }
}

struct RequestRowPreview: PreviewProvider {
  static var previews: some View {
    var request: Request!
    var requestsList: RequestsList!
    let _ = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      try $0.defaultDatabase.read { db in
        request = try Request.all.fetchOne(db)
        requestsList = try RequestsList.all.fetchOne(db)!
      }
    }

    NavigationStack {
      List {
        RequestRow(
          color: requestsList.color,
          isPastDue: false,
          notes: request.notes.replacingOccurrences(of: "\n", with: " "),
          request: request,
          requestsList: requestsList,
          showCompleted: true
        )
      }
    }
  }
}
