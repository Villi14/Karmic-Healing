import IssueReporting
import SharingGRDB
import SwiftUI
import Common
import Resources

struct RequestFormView: View {
  @FetchOne var requestsList: RequestsList
  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss
  
  @State var request: Request.Draft
  @State private var selectedDate: Date = Date()
  
  let onSave: (() -> Void)?
  
  init(request: Request.Draft, requestsList: RequestsList, onSave: (() -> Void)? = nil) {
    _requestsList = FetchOne(wrappedValue: requestsList, RequestsList.find(requestsList.id))
    self.request = request
    self.onSave = onSave
    
    if let dueDate = request.dueDate {
      self._selectedDate = State(initialValue: dueDate)
    }
  }
  
  var body: some View {
    Form {
      TextField("title".loc(), text: $request.title)
        .font(.system(.title2, design: .rounded, weight: .semibold))
      
      ZStack {
        if request.notes.isEmpty {
          TextEditor(text: .constant("notes".loc()))
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
            Text("date".loc())
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)
        .onChange(of: request.isDateSet) { _, isSet in
          if isSet {
            request.dueDate = selectedDate
          } else {
            request.dueDate = nil
          }
        }
        
        if let _ = request.dueDate {
          DatePicker(
            "",
            selection: $selectedDate,
            displayedComponents: [.date, .hourAndMinute]
          )
          .tint(ResourcesAsset.Colors.clam.swiftUIColor)
          .padding(.vertical, DesignConstants.paddingTiny)
          .onChange(of: selectedDate) { _, newDate in
            request.dueDate = newDate
          }
        }
      }
      
      Section {
        Picker(selection: $request.priority) {
          Text("none".loc()).tag(Priority?.none)
          Divider()
          Text("high".loc()).tag(Priority.high)
          Text("medium".loc()).tag(Priority.medium)
          Text("low".loc()).tag(Priority.low)
        } label: {
          HStack {
            Image(systemName: "exclamationmark")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text("priority".loc())
          }
        }
      }
    }
    .padding(.top, DesignConstants.paddingNegativeXLarge)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button(action: saveButtonTapped) {
          Text("save".loc())
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        .disabled(request.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button("cancel".loc()) {
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      }
    }
  }
  
  private func saveButtonTapped() {
    withErrorReporting {
      try database.write { db in
        // Check if this is a new request (not editing existing)
        let isNewRequest = request.id == nil
        
        // Save the request
        try Request.upsert(request).fetchOne(db)
        
        // Rule 2: If adding a new subordinate request and main request is completed, reset it to uncompleted
        if isNewRequest && requestsList.isCompleted {
          try RequestsList
            .find(requestsList.id)
            .update { $0.isCompleted = false }
            .execute(db)
        }
      }
    }
    onSave?()
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
      $0.defaultDatabase = try appDatabase()
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
        .navigationTitle("detail".loc())
    }
  }
}
