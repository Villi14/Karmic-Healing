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
        }
      }
      .navigationTitle(String(localized: "reminders", bundle: .main))
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.automatic)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
          }
        }
      }
    }
  }
}

#Preview {
  ZStack {
    GgWithGradientView()
    RemindersView(store: .init(
      initialState: .init(),
      reducer: {
        Reminders()
      }
    ))
  }
}

