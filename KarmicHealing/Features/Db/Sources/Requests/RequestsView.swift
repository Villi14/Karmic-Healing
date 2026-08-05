//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct RequestsView: View {
  @Environment(\.dismiss) var dismiss

  /// Owned by this view, so every push starts from a clean model and its `@FetchAll`
  /// observers die with the screen.
  @State private var model = RequestsListsModel()

  public init() {}

  public var body: some View {
    RequestsListsView(model: model)
      .navigationTitle("requests".loc)
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.automatic)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .sacral))
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
    AuraBackground(level: .sacral)
    NavigationStack {
      RequestsView()
    }
  }
}
