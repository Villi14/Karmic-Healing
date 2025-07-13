//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct RequestsView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @Dependency(\.context) var context

  static let model = RequestsListsModel()

  public let store: StoreOf<Requests>

  public init(store: StoreOf<Requests>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        if context == .live {
          RequestsListsView(model: Self.model)
        }
      }
      .navigationTitle(String(localized: "requests", bundle: .main))
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
  RequestsView(store: .init(
    initialState: .init(),
    reducer: {
      Requests()
    }
  ))
}

