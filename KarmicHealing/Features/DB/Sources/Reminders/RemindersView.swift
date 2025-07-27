//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct RemindersView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @Dependency(\.context) var context
  
  static let model = RemindersListsModel()

  public let store: StoreOf<Reminders>
  
  public init(store: StoreOf<Reminders>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        if context == .live {
          RemindersListsView(model: Self.model)
//          .onChange(of: viewStore.selectedReminderID) { id, _ in
//            guard let id else { return }
//            if let reminder = try? Self.model.database.read({ db in try Reminder.fetchOne(db, id: id) }),
//               let remindersList = try? Self.model.database.read({ db in try RemindersList.fetchOne(db, id: reminder.remindersListID) }) {
//              Self.model.destination = .detail(RemindersDetailModel(detailType: .remindersList(remindersList), selectedReminderID: id))
//            }
//          }
        }
      }
      .navigationTitle(String(localized: "reminders", bundle: .main))
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.automatic)
      .navigationBarBackgroundColor(ResourcesAsset.Colors.background.swiftUIColor)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          }
        }
      }
    }
  }
}

#Preview {
  RemindersView(store: .init(
    initialState: .init(),
    reducer: {
      Reminders()
    }
  ))
}

