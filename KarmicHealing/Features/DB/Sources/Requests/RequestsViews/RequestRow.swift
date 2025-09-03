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
      if !isCompleted {
        Button {
          editRequest = Request.Draft(request)
        } label: {
          Image(systemName: "info.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(ResourcesAsset.Colors.clarity.swiftUIColor)
        }
        .tint(color)
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
