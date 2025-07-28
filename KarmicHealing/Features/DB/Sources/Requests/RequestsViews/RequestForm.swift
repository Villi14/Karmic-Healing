import IssueReporting
import SharingGRDB
import SwiftUI
import Common
import Resources

struct RequestFormView: View {
  @FetchAll(RequestsList.order(by: \.title)) var requestsLists
  @FetchOne var requestsList: RequestsList

  @State var request: Request.Draft

  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss

  init(request: Request.Draft, requestsList: RequestsList) {
    _requestsList = FetchOne(wrappedValue: requestsList, RequestsList.find(requestsList.id))
    self.request = request
  }

  var body: some View {
    Form {
      TextField(String(localized: "title", bundle: .main), text: $request.title)

      ZStack {
        if request.notes.isEmpty {
          TextEditor(text: .constant(String(localized: "notes", bundle: .main)))
            .foregroundStyle(.placeholder)
            .accessibilityHidden(true, isEnabled: false)
        }

        TextEditor(text: $request.notes)
      }
      .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      .tint(ResourcesAsset.Colors.clam.swiftUIColor)
      .lineLimit(4)
      .padding(.horizontal, DesignConstants.paddingNegativeSmall)

      Section {
        Toggle(isOn: $request.isDateSet.animation()) {
          HStack {
            Image(systemName: "calendar")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text(String(localized: "date", bundle: .main))
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)

        if let dueDate = request.dueDate {
          DatePicker(
            "",
            selection: $request.dueDate[coalesce: dueDate],
            displayedComponents: [.date, .hourAndMinute]
          )
          .tint(ResourcesAsset.Colors.clam.swiftUIColor)
          .padding(.vertical, DesignConstants.paddingTiny)
        }
      }

      Section {
        Toggle(isOn: $request.isFlagged) {
          HStack {
            Image(systemName: "flag")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
            Text(String(localized: "flag", bundle: .main))
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)

        Picker(selection: $request.priority) {
          Text(String(localized: "none", bundle: .main)).tag(Priority?.none)
          Divider()
          Text(String(localized: "high", bundle: .main)).tag(Priority.high)
          Text(String(localized: "medium", bundle: .main)).tag(Priority.medium)
          Text(String(localized: "low", bundle: .main)).tag(Priority.low)
        } label: {
          HStack {
            Image(systemName: "exclamationmark")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text(String(localized: "priority", bundle: .main))
          }
        }

        Picker(selection: $request.requestsListID) {
          ForEach(requestsLists) { requestsList in
            Text(requestsList.title)
              .buttonStyle(.plain)
              .tag(requestsList.id)
          }
        } label: {
          HStack {
            Image(systemName: "list.bullet")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(requestsList.color)
            Text(String(localized: "list", bundle: .main))
          }
        }
        .task(id: request.requestsListID) {
          await withErrorReporting {
            try await $requestsList.load(RequestsList.find(request.requestsListID))
          }
        }
      }
    }
    .padding(.top, DesignConstants.paddingNegativeXLarge)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button(action: saveButtonTapped) {
          Text(String(localized: "save", bundle: .main))
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        .disabled(request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button(String(localized: "cancel", bundle: .main)) {
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      }
    }
  }

  private func saveButtonTapped() {
    withErrorReporting {
      try database.write { db in
        try Request.upsert(request).fetchOne(db)
      }
    }
    dismiss()
  }
}

extension Request.Draft {
  fileprivate var isDateSet: Bool {
    get { dueDate != nil }
    set { dueDate = newValue ? Date() : nil }
  }
}

extension Optional {
  fileprivate subscript(coalesce coalesce: Wrapped) -> Wrapped {
    get { self ?? coalesce }
    set { self = newValue }
  }
}

struct RequestFormPreview: PreviewProvider {
  static var previews: some View {
    let (requestsList, request) = try! prepareDependencies {
      $0.defaultDatabase = try Db.appDatabase()
      return try $0.defaultDatabase.write { db in
        let requestsList = try RequestsList.all.fetchOne(db)!
        return (
          requestsList,
          try Request.where { $0.requestsListID == requestsList.id }.fetchOne(db)!
        )
      }
    }
    
    NavigationStack {
      RequestFormView(request: Request.Draft(request), requestsList: requestsList)
        .navigationTitle(String(localized: "detail", bundle: .main))
    }
  }
}
