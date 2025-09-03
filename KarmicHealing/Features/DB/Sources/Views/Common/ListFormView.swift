import IssueReporting
import SharingGRDB
import SwiftUI
import Common
import Resources

struct ListFormView<ListType: Identifiable>: View {
  @Dependency(\.defaultDatabase) private var database
  
  @Binding var list: ListType
  @Binding var title: String
  @Binding var color: Color
  let onSave: (ListType) -> Void
  @Environment(\.dismiss) var dismiss
  
  init(
    list: Binding<ListType>,
    title: Binding<String>,
    color: Binding<Color>,
    onSave: @escaping (ListType) -> Void
  ) {
    self._list = list
    self._title = title
    self._color = color
    self.onSave = onSave
  }
  
  var body: some View {
    Form {
      Section {
        VStack {
          TextField("list_name".loc(), text: $title)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .foregroundStyle(color)
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .tint(ResourcesAsset.Colors.clam.swiftUIColor)
            .padding(.horizontal, DesignConstants.spacingXLarge)
            .padding(.vertical)
        }
      }
      
      ColorPicker("color".loc(), selection: $color)
        .tint(ResourcesAsset.Colors.clam.swiftUIColor)
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem {
        Button("save".loc()) {
          onSave(list)
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button("cancel".loc()) {
          dismiss()
        }
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      }
    }
  }
}

#Preview {
  NavigationStack {
    ListFormView(
      list: .constant(RequestsList.Draft(RequestsList(id: UUID(), title: "Test"))),
      title: .constant("Test List"),
      color: .constant(.blue)
    ) { _ in
      print("Save tapped")
    }
    .navigationTitle("new_list".loc())
  }
} 
