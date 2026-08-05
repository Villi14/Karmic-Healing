import IssueReporting
import SQLiteData
import SwiftUI
import Common
import Resources

struct RequestFormView: View {
  @FetchOne var requestsList: RequestsList
  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss
  
  @State var request: Request.Draft

  let title: String
  let onSave: (() -> Void)?

  init(
    request: Request.Draft,
    requestsList: RequestsList,
    title: String,
    onSave: (() -> Void)? = nil
  ) {
    _requestsList = FetchOne(wrappedValue: requestsList, RequestsList.find(requestsList.id))
    self.request = request
    self.title = title
    self.onSave = onSave
  }
  
  var body: some View {
    Form {
      TextField("title".loc, text: $request.title, axis: .vertical)
        .font(Typography.title)
        .tint(Spectrum.sacral.color)

      TextField("notes".loc, text: $request.notes, axis: .vertical)
        .lineLimit(DesignConstants.notesLineLimit...)
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .tint(Spectrum.sacral.color)
    }
    .padding(.top, DesignConstants.paddingNegativeXLarge)
    .scrollContentBackground(.hidden)
    .karmicFormTitle(title)
    .background { AuraBackground(level: .sacral) }
    .toolbar {
      ToolbarItem {
        Button(action: saveButtonTapped) {
          Text("save".loc)
        }
        .foregroundStyle(AuraGradient.gradient(for: .sacral))
        .disabled(request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button("cancel".loc) {
          dismiss()
        }
        .foregroundStyle(AuraGradient.gradient(for: .sacral))
      }
    }
  }
  
  private func saveButtonTapped() {
    withErrorReporting {
      try database.write { db in
        try Request.upsert { request }.fetchOne(db)

        // The subrequest takes its request's date, and a subrequest added to an already
        // fulfilled request reopens it.
        try RequestsList.inheritDueDate(of: requestsList.id, in: db)
        try RequestsList.syncCompletion(of: requestsList.id, in: db)
      }
    }
    onSave?()
    dismiss()
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
      $0.defaultDatabase = try appDatabase()
      return try $0.defaultDatabase.write { db in
        let requestsList = try RequestsList.all.fetchOne(db)!
        return (
          requestsList,
          try Request.where { $0.requestsListID.eq(requestsList.id) }.fetchOne(db)!
        )
      }
    }
    
    NavigationStack {
      RequestFormView(
        request: Request.Draft(request),
        requestsList: requestsList,
        title: "detail".loc
      )
    }
  }
}
