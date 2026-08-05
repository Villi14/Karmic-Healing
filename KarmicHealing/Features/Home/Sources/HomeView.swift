//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Resources
import Common
import BalancingEnergyList
import BalancingEnergy
import Db
import AppSettings

public struct HomeView: View {
  @Bindable var store: StoreOf<Home>

  public init(store: StoreOf<Home>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      ZStack {
        AuraBackground(level: .heart)

        ScrollView {
          VStack(alignment: .leading, spacing: DesignConstants.spacingLarge) {
            HomeHeroCardView {
              store.send(.didTap(.balancingEnergyButton))
            }

            Text("home_tools".loc)
              .font(Typography.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .padding(.top, DesignConstants.paddingSmall)

            LazyVGrid(
              columns: [
                GridItem(.flexible(), spacing: DesignConstants.spacingMedium),
                GridItem(.flexible(), spacing: DesignConstants.spacingMedium)
              ],
              spacing: DesignConstants.spacingMedium
            ) {
              ForEach(store.homeButtons.filter { $0 != .balancingEnergyButton }, id: \.title) { homeButton in
                Button(action: { store.send(.didTap(homeButton)) }) {
                  HomeButtonView(homeButton: homeButton)
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingXLarge)
          .karmicContentWidth()
        }
      }
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .navigationTitle("karmic_healing".loc)
      .navigationBarTitleDisplayMode(.inline)
    } destination: { store in
      switch store.case {
      case .balancingEnergyList(let store):
        BalancingEnergyListView(store: store)
      case .balancingEnergy(let store):
        BalancingEnergyView(store: store)
      case .requests:
        RequestsView()
      case .reminders(let store):
        RemindersView(store: store)
      case .appSettings(let store):
        AppSettingsView(store: store)
      }
    }
  }

}

#Preview {
  ZStack {
    AuraBackground(level: .heart)
    HomeView(store: .init(
      initialState: .init(),
      reducer: {
        Home()
      }
    ))
  }
}
