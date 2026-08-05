import IssueReporting
import SQLiteData
import SwiftUI
import Common
import Resources

struct RequestsListForm: View {
  @Dependency(\.defaultDatabase) private var database
  @Environment(\.dismiss) var dismiss
  
  @State var requestsList: RequestsList.Draft
  @State private var isDueDateEnabled: Bool
  @State private var selectedDate: Date = Date()
  
  let title: String

  init(requestsList: RequestsList.Draft, title: String) {
    self.requestsList = requestsList
    self.title = title
    _isDueDateEnabled = State(initialValue: requestsList.dueDate != nil)
    if let dueDate = requestsList.dueDate {
      _selectedDate = State(initialValue: dueDate)
    }
  }
  
  var body: some View {
    Form {
      Section {
        VStack {
          TextField("request_placeholder".loc, text: $requestsList.title, axis: .vertical)
            .font(Typography.title)
            .foregroundStyle(AuraGradient.gradient(for: requestsList.color))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .tint(Spectrum.sacral.color)
            .padding(.horizontal, DesignConstants.spacingXLarge)
            .padding(.vertical)
        }
      }
      
      Section {
        TextField("notes".loc, text: $requestsList.notes, axis: .vertical)
          .lineLimit(DesignConstants.notesLineLimit...)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .tint(Spectrum.sacral.color)
      }

      ColorPicker("color".loc, selection: $requestsList.color)
        .tint(Spectrum.sacral.color)
      
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
              .foregroundStyle(AuraGradient.gradient(for: .sacral))
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
          .tint(Spectrum.sacral.color)
          .padding(.vertical, DesignConstants.paddingTiny)
          .onChange(of: selectedDate) { _, newDate in
            requestsList.dueDate = newDate
          }
        }
      }
    }
    .scrollContentBackground(.hidden)
    .karmicFormTitle(title)
    .background { AuraBackground(level: .sacral) }
    .toolbar {
      ToolbarItem {
        Button("save".loc) {
          withErrorReporting {
            try database.write { db in
              try RequestsList.upsert { requestsList }
                .execute(db)

              // A brand new request has nothing under it yet; an edited one passes its date on.
              if let id = requestsList.id {
                try RequestsList.inheritDueDate(of: id, in: db)
              }
            }
          }
          dismiss()
        }
        .foregroundStyle(AuraGradient.gradient(for: .sacral))
        .disabled(requestsList.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button("cancel".loc) {
          dismiss()
        }
        .foregroundStyle(AuraGradient.gradient(for: .sacral))
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
      RequestsListForm(requestsList: RequestsList.Draft(), title: "request_placeholder".loc)
    }
  }
}
