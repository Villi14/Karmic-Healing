//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct RequestsView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss

  public let store: StoreOf<Requests>

  public init(store: StoreOf<Requests>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            ResourcesAsset.Colors.clam.swiftUIColor.opacity(0.1),
            ResourcesAsset.Colors.background.swiftUIColor
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
          Spacer()
        }
        .navigationTitle(String(localized: "requests", bundle: .main))
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.automatic)
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
  RequestsView(store: .init(
    initialState: .init(),
    reducer: {
      Requests()
    }
  ))
}

