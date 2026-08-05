import IssueReporting
import SQLiteData
import SwiftUI
import Common

struct ListFormView<ListType: Identifiable>: View {
  @Dependency(\.defaultDatabase) private var database
  
  @Binding var list: ListType
  @Binding var title: String
  @Binding var color: Color
  let screenTitle: String
  let onSave: (ListType) -> Void
  @Environment(\.dismiss) var dismiss

  init(
    list: Binding<ListType>,
    title: Binding<String>,
    color: Binding<Color>,
    screenTitle: String,
    onSave: @escaping (ListType) -> Void
  ) {
    self._list = list
    self._title = title
    self._color = color
    self.screenTitle = screenTitle
    self.onSave = onSave
  }
  
  var body: some View {
    Form {
      Section {
        VStack {
          // The title wears the colour being picked below it, so the picker shows its
          // effect where the user is looking rather than only after saving.
          TextField("reminder_placeholder".loc, text: $title, axis: .vertical)
            .font(Typography.title)
            .foregroundStyle(AuraGradient.gradient(for: color))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .tint(Spectrum.throat.color)
            .padding(.horizontal, DesignConstants.spacingXLarge)
            .padding(.vertical)
        }
      }
      
      ColorPicker("color".loc, selection: $color)
        .tint(Spectrum.throat.color)
    }
    .scrollContentBackground(.hidden)
    .karmicFormTitle(screenTitle)
    .background { AuraBackground(level: .throat) }
    .toolbar {
      ToolbarItem {
        Button("save".loc) {
          onSave(list)
          dismiss()
        }
        .foregroundStyle(AuraGradient.gradient(for: auraLevel))
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button("cancel".loc) {
          dismiss()
        }
        .foregroundStyle(AuraGradient.gradient(for: auraLevel))
      }
    }
  }

  private var auraLevel: Spectrum {
    list is RequestsList ? .sacral : .solar
  }
}

#Preview {
  NavigationStack {
    ListFormView(
      list: .constant(RequestsList.Draft(RequestsList(id: UUID(), title: "Test"))),
      title: .constant("Test List"),
      color: .constant(.blue),
      screenTitle: "new_list".loc
    ) { _ in
      print("Save tapped")
    }
  }
} 
