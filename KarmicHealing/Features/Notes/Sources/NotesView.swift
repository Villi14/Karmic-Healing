//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct NotesView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss

  public let store: StoreOf<Notes>

  public init(store: StoreOf<Notes>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        ResourcesAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()
        VStack {
          Spacer()
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
  NotesView(store: .init(
    initialState: .init(),
    reducer: {
      Notes()
    }
  ))
}

