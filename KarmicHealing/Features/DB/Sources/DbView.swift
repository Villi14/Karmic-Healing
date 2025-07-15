import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct DbView<R: Reducer, ListsView: View>: View where R.State: Equatable {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @Dependency(\.context) var context

  public let store: StoreOf<R>
  public let listsView: () -> ListsView
  public let title: String

  public init(store: StoreOf<R>, title: String, listsView: @escaping () -> ListsView) {
    self.store = store
    self.title = title
    self.listsView = listsView
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { _ in
      VStack {
        if context == .live {
          listsView()
        }
      }
      .navigationTitle(title)
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
