import SharingGRDB
import SwiftUI
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
    HStack {
      HStack(alignment: .firstTextBaseline) {
        Button(action: completeButtonTapped) {
          Image(systemName: isCompleted ? "circle.inset.filled" : "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 18)
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)
            .padding([.trailing], 5)
        }

        VStack(alignment: .leading) {
          title(for: request)

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
        HStack {
          if request.isFlagged {
            Image(systemName: "flag")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: 18)
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
          }
          
          Button {
            editRequest = Request.Draft(request)
          } label: {
            Image(systemName: "info.circle")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(height: 18)
              .foregroundStyle(ResourcesAsset.Colors.clarity.swiftUIColor)
          }
          .tint(color)
        }
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
      }
      .tint(ResourcesAsset.Colors.energy.swiftUIColor)

      Button(request.isFlagged ? String(localized: "unflag", bundle: .main) : String(localized: "flag", bundle: .main)) {
        withErrorReporting {
          try database.write { db in
            try Request
              .find(request.id)
              .update { $0.isFlagged.toggle() }
              .execute(db)
          }
        }
      }
      .tint(ResourcesAsset.Colors.friendly.swiftUIColor)

      Button(String(localized: "details", bundle: .main)) {
        editRequest = Request.Draft(request)
      }
      .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
    }
    .sheet(item: $editRequest) { request in
      NavigationStack {
        RequestFormView(request: request, requestsList: requestsList)
          .navigationTitle(String(localized: "details", bundle: .main))
      }
    }
    .task(id: isCompleted) {
      guard !showCompleted else { return }

      guard
        isCompleted, isCompleted != request.isCompleted
      else { return }

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
    }
  }

  private var dueText: Text {
    if let date = request.dueDate {
      Text(date.formatted(date: .numeric, time: .shortened))
        .foregroundStyle(isPastDue ? .red : .gray)
    } else {
      Text("")
    }
  }

  private func title(for request: Request) -> some View {
    return HStack(alignment: .firstTextBaseline) {
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
