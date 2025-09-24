import IssueReporting
import SharingGRDB
import SwiftUI
import Common
import Resources

struct RequestsListForm: View {
  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss
  
  @State var requestsList: RequestsList.Draft
  @State private var isDueDateEnabled: Bool
  @State private var selectedDate: Date = Date()
  
  init(requestsList: RequestsList.Draft) {
    self.requestsList = requestsList
    _isDueDateEnabled = State(initialValue: requestsList.dueDate != nil)
    if let dueDate = requestsList.dueDate {
      _selectedDate = State(initialValue: dueDate)
    }
  }
  
  var body: some View {
    Form {
      Section {
        VStack {
          TextField("request_placeholder".loc, text: $requestsList.title)
            .font(.system(.title, design: .rounded, weight: .bold))
            .foregroundStyle(requestsList.color)
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .tint(ResourcesAsset.Colors.clam.swiftUIColor)
            .padding(.horizontal, DesignConstants.spacingXLarge)
            .padding(.vertical)
        }
      }
      
      ColorPicker("color".loc, selection: $requestsList.color)
        .tint(ResourcesAsset.Colors.clam.swiftUIColor)
      
      Section {
        Toggle(isOn: $isDueDateEnabled.animation()) {
          HStack {
            Image(systemName: "calendar")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(
                width: DesignConstants.frameHeightSmall,
                height: DesignConstants.frameHeightSmall
              )
              .foregroundStyle(ResourcesAsset.Colors.energy.swiftUIColor)
            Text("date".loc)
          }
        }
        .tint(ResourcesAsset.Colors.health.swiftUIColor)
        .onChange(of: isDueDateEnabled) { _, isSet in
          if isSet {
            requestsList.dueDate = selectedDate
          } else {
            requestsList.dueDate = nil
          }
        }
        
        if let _ = requestsList.dueDate, isDueDateEnabled {
          DatePicker(
            "",
            selection: $selectedDate,
            displayedComponents: [.date, .hourAndMinute]
          )
          .tint(ResourcesAsset.Colors.clam.swiftUIColor)
          .padding(.vertical, DesignConstants.paddingTiny)
          .onChange(of: selectedDate) { _, newDate in
            requestsList.dueDate = newDate
          }
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("save".loc) {
          withErrorReporting {
            try database.write { db in
              try RequestsList.upsert(requestsList)
                .execute(db)
            }
          }
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        .disabled(requestsList.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button("cancel".loc) {
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      }
    }
  }
}

struct RequestsListFormPreviews: PreviewProvider {
  static var previews: some View {
    let _ = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
    }
    
    NavigationStack {
      RequestsListForm(requestsList: RequestsList.Draft())
        .navigationTitle("request_placeholder".loc)
    }
  }
}
