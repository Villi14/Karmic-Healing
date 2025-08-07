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
      Button(String(localized: "delete", bundle: .main), role: .destructive) {
        withErrorReporting {
          try database.write { db in
            try Request.delete(request).execute(db)
          }
        }
        onRequestCompletionChanged?()
      }
      .tint(ResourcesAsset.Colors.energy.swiftUIColor)
      Button(String(localized: "details", bundle: .main)) {
        editRequest = Request.Draft(request)
      }
      .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
    }
    .sheet(item: $editRequest) { item in
      NavigationStack {
        RequestFormView(
          request: item,
          requestsList: requestsList,
          onSave: {
            onRequestCompletionChanged?()
          }
        )
        .navigationTitle(String(localized: "details", bundle: .main))
      }
    }
    .task(id: isCompleted) {
      guard !showCompleted else { return }
      guard isCompleted, isCompleted != request.isCompleted else { return }
      do {
        try await Task.sleep(for: .seconds(2))
        toggleCompletion()
      } catch {}
    }
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
