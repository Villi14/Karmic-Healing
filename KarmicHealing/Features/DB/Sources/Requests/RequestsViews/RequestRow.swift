import GRDB
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
    showCompleted: Bool
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
    HStack {
      HStack(alignment: .firstTextBaseline) {
        Button(action: completeButtonTapped) {
          Image(systemName: isCompleted ? "circle.inset.filled" : "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)
            .padding([.trailing], DesignConstants.paddingSmall)
        }
        VStack(alignment: .leading) {
          HStack(alignment: .firstTextBaseline) {
            if let priority = request.priority {
              Text(String(repeating: "!", count: priority.rawValue))
                .foregroundStyle(isCompleted ? ResourcesAsset.Colors.textSecondary.swiftUIColor : requestsList.color)
            }
            Text(request.title)
              .foregroundStyle(
                isCompleted ? ResourcesAsset.Colors.textSecondary.swiftUIColor : ResourcesAsset.Colors.textPrimary.swiftUIColor
              )
          }
          .font(.title3)
          if !notes.isEmpty {
            Text(notes)
              .font(.subheadline)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .lineLimit(2)
          }
        }
      }
      Spacer()
      HStack(spacing: DesignConstants.paddingMedium) {
        Button {
          editRequest = Request.Draft(request)
        } label: {
          Image(systemName: "info.circle")
            .font(.title3)
            .foregroundStyle(ResourcesAsset.Colors.clarity.swiftUIColor)
        }
        .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
        
        Button {
          deleteRequest()
        } label: {
          Image(systemName: "trash")
            .font(.title3)
            .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
        }
        .tint(ResourcesAsset.Colors.energy.swiftUIColor)
      }
    }
    .buttonStyle(.borderless)
    .swipeActions {
      Button("delete".loc(), role: .destructive) {
        withErrorReporting {
          try database.write { db in
            try Request.delete(request).execute(db)
          }
        }
      }
      .tint(ResourcesAsset.Colors.energy.swiftUIColor)
      Button("details".loc()) {
        editRequest = Request.Draft(request)
      }
      .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
    }
    .sheet(item: $editRequest) { item in
      NavigationStack {
        RequestFormView(
          request: item,
          requestsList: requestsList,
          onSave: nil
        )
        .navigationTitle("details".loc())
      }
    }
  }

  private func completeButtonTapped() {
    toggleCompletion()
  }

  private func toggleCompletion() {
    withErrorReporting {
      try database.write { db in
        // Toggle the completion status of the current request
        isCompleted =
        try Request
          .find(request.id)
          .update { $0.isCompleted.toggle() }
          .returning(\.isCompleted)
          .fetchOne(db) ?? isCompleted
        
        // Update the parent RequestsList completion status based on new logic
        try updateMainRequestCompletionStatus(in: db)
      }
    }
  }
  
  private func updateMainRequestCompletionStatus(in db: Database) throws {
    // Get all subordinate requests for this main request
    let totalRequests = try Request.where { $0.requestsListID == requestsList.id }.fetchCount(db)
    let completedRequests = try Request.where { $0.requestsListID == requestsList.id && $0.isCompleted }.fetchCount(db)
    
    let allSubRequestsCompleted = totalRequests > 0 && totalRequests == completedRequests
    
    
    // Rule 4: If any subordinate request is unchecked, main request should be unchecked
    // But we don't automatically set main request to checked when all subordinates are completed
    if !allSubRequestsCompleted && totalRequests > 0 {
      // Reset main request to uncompleted if any subordinate is uncompleted
      try RequestsList
        .find(requestsList.id)
        .update { $0.isCompleted = false }
        .execute(db)
    }
    // Note: We don't automatically set main request to completed when all subordinates are completed
    // The user must manually check the main request
  }
  
  private func deleteRequest() {
    withErrorReporting {
      try database.write { db in
        try Request.delete(request).execute(db)
        
        // Update main request completion status after deletion
        try updateMainRequestCompletionStatus(in: db)
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
