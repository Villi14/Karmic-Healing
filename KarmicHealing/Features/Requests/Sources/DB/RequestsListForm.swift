import IssueReporting
import SharingGRDB
import SwiftUI
import Resources

struct RequestsListForm: View {
  @Dependency(\.defaultDatabase) private var database
  
  @State var requestsList: RequestsList.Draft
  @Environment(\.dismiss) var dismiss
  
  init(requestsList: RequestsList.Draft) {
    self.requestsList = requestsList
  }
  
  var body: some View {
    Form {
      Section {
        VStack {
          TextField(String(localized: "list_name", bundle: .main), text: $requestsList.title)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(requestsList.color)
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .tint(ResourcesAsset.Colors.clam.swiftUIColor)
            .padding(.horizontal, 32)
            .padding(.vertical)
        }
      }

      ColorPicker(String(localized: "color", bundle: .main), selection: $requestsList.color)
        .tint(ResourcesAsset.Colors.clam.swiftUIColor)
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button(String(localized: "save", bundle: .main)) {
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
        Button(String(localized: "cancel", bundle: .main)) {
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
        .navigationTitle(String(localized: "new_list", bundle: .main))
    }
  }
}
