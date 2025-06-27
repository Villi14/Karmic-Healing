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

    if context == .live {
      try! prepareDependencies {
        $0.defaultDatabase = try appDatabase()
      }
    }
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        ResourcesAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()
        VStack {
          RemindersListsView(model: Self.model)
        }
        .navigationTitle(String(localized: "notes", bundle: .main))
        .navigationBarBackButtonHidden(true)
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
}

#Preview {
  RemindersView(store: .init(
    initialState: .init(),
    reducer: {
      Reminders()
    }
  ))
}

