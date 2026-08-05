//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct RemindersView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss

  /// Owned by this view, so every push starts from a clean model and its `@FetchAll`
  /// observers die with the screen. The deep-link ids come from the TCA state that
  /// pushed us here.
  @State private var model: RemindersListsModel

  public init(store: StoreOf<Reminders>) {
    _model = State(
      wrappedValue: RemindersListsModel(
        selectedReminderID: store.selectedReminderID,
        selectedReminderListID: store.selectedReminderListID
      )
    )
  }

  public var body: some View {
    RemindersListsView(model: model)
      .navigationTitle("reminders".loc)
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.automatic)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .solar))
          }
        }
      }
  }
}

#Preview {
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }
  ZStack {
    AuraBackground(level: .solar)
    NavigationStack {
      RemindersView(store: .init(
        initialState: .init(),
        reducer: {
          Reminders()
        }
      ))
    }
  }
}
