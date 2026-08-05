import GRDB
import SQLiteData
import SwiftUI
import Common
import Resources

struct RequestRow: View {
  let color: Color
  let notes: String
  let request: Request
  let requestsList: RequestsList
  let showCompleted: Bool
  /// Screens that mix requests — All, Fulfilled, search — name the request each subrequest
  /// serves. A request's own screen carries it in the header, so it stays quiet there.
  let showsRequest: Bool

  @State var editRequest: Request.Draft?
  @State var isCompleted: Bool

  @Dependency(\.defaultDatabase) private var database

  init(
    color: Color,
    notes: String,
    request: Request,
    requestsList: RequestsList,
    showCompleted: Bool,
    showsRequest: Bool = false
  ) {
    self.color = color
    self.notes = notes
    self.request = request
    self.requestsList = requestsList
    self.showCompleted = showCompleted
    self.showsRequest = showsRequest
    self.isCompleted = request.isCompleted
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Button(action: completeButtonTapped) {
        Image(systemName: isCompleted ? "circle.inset.filled" : "circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameHeightSmall)
          .foregroundStyle(AuraGradient.gradient(for: color))
          .padding([.trailing], DesignConstants.paddingSmall)
          .animation(Motion.touch, value: isCompleted)
      }

      // Everything beside the radio button opens the subrequest.
      HStack {
        VStack(alignment: .leading) {
          if showsRequest {
            RowBadge(
              title: requestsList.title,
              tone: requestsList.color,
              iconName: "arrow.turn.left.up"
            )
          }
          Text(request.title)
            .font(Typography.listTitle)
            .strikethrough(isCompleted, pattern: .solid, color: ResourcesAsset.Colors.textSecondary.swiftUIColor)
            .foregroundStyle(
              isCompleted ? ResourcesAsset.Colors.textSecondary.swiftUIColor : ResourcesAsset.Colors.textPrimary.swiftUIColor
            )
          if !notes.isEmpty {
            Text(notes)
              .font(Typography.bodySecondary)
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .lineLimit(2)
          }
        }
        Spacer(minLength: 0)

        Image(systemName: "info.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameHeightSmall)
          .foregroundStyle(AuraGradient.gradient(for: color))
      }
      .contentShape(Rectangle())
      .onTapGesture {
        editRequest = Request.Draft(request)
      }
    }
    // Only the row's own radio button is borderless; the swipe buttons below must be left to
    // the styling every other row's swipe buttons get.
    .buttonStyle(.borderless)
    .padding(.horizontal, DesignConstants.paddingLarge)
    .padding(.vertical, DesignConstants.paddingMedium)
    .cardStyle(
      tone: color,
      elevation: .flat,
      gradient: AuraGradient.gradient(for: color)
    )
    .rowSwipeActions(
      onDelete: deleteRequest,
      onEdit: { editRequest = Request.Draft(request) }
    )
    .sheet(item: $editRequest) { item in
      NavigationStack {
        RequestFormView(
          request: item,
          requestsList: requestsList,
          title: "details".loc,
          onSave: nil
        )
      }
    }
  }

  private func completeButtonTapped() {
    toggleCompletion()
  }

  private func toggleCompletion() {
    withErrorReporting {
      try database.write { db in
        try Request
          .find(request.id)
          .update { $0.isCompleted.toggle() }
          .execute(db)
        isCompleted = try Request
          .find(request.id)
          .select { $0.isCompleted }
          .fetchOne(db) ?? isCompleted

        // Reopening a subrequest reopens the request above it; fulfilling the last one only
        // unlocks that request's radio button, it never taps it for the user.
        try RequestsList.syncCompletion(of: requestsList.id, in: db)
      }
    }
  }

  private func deleteRequest() {
    withErrorReporting {
      try database.write { db in
        try Request.delete(request).execute(db)
        try RequestsList.syncCompletion(of: requestsList.id, in: db)
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
          notes: request.notes.replacingOccurrences(of: "\n", with: " "),
          request: request,
          requestsList: requestsList,
          showCompleted: true
        )
      }
    }
  }
}
