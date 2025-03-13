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

  private struct ViewState: Equatable {
    let title: String

    init(state: Requests.State) {
      self.title = state.title
    }
  }

  public var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      ZStack {
        ResourcesAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()
        VStack {
          Spacer()
        }
        .navigationTitle(viewStore.title)
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
  RequestsView(store: .init(
    initialState: .init(title: "Requests"),
    reducer: {
      Requests()
    }
  ))
}

