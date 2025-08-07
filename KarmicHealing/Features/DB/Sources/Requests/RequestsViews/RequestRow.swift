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
  let onRequestCompletionChanged: (() -> Void)?

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
    onRequestCompletionChanged: (() -> Void)? = nil
  ) {
    self.color = color
    self.isPastDue = isPastDue
    self.notes = notes
    self.request = request
    self.requestsList = requestsList
    self.showCompleted = showCompleted
    self.onRequestCompletionChanged = onRequestCompletionChanged
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
        // Notify parent view about deletion
        onRequestCompletionChanged?()
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
      onEditCompleted: {
        // Notify parent view about edit completion
        onRequestCompletionChanged?()
      },
      onShowDetails: {
        editRequest = Request.Draft(request)
      },
      formView: { request, requestsList in
        AnyView(RequestFormView(
          request: request, 
          requestsList: requestsList,
          onSave: {
            // Notify parent view about save completion
            onRequestCompletionChanged?()
          }
        ))
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
      
      print("DEBUG: RequestRow toggleCompletion - request \(request.id) isCompleted: \(isCompleted)")
      
      // Update the parent RequestsList completion status
      try requestsList.updateCompletionStatus(in: database)
      
      print("DEBUG: RequestRow toggleCompletion - updated RequestsList completion status")
      
      // Force refresh of the database to ensure UI updates
      try database.write { _ in
        // This empty write will trigger database observers
      }
      
      // Force refresh of @FetchOne observers
      try database.write { _ in
        // This additional write ensures all observers are triggered
      }
      
      // Notify parent view about completion change
      onRequestCompletionChanged?()
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
