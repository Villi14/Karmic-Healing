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
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
        ZStack {
          LinearGradient(
            gradient: Gradient(colors: [
              ResourcesAsset.Colors.clam.swiftUIColor.opacity(DesignConstants.opacityLow),
              ResourcesAsset.Colors.background.swiftUIColor
            ]),
            startPoint: .top,
            endPoint: .bottom
          )
          .ignoresSafeArea()

          GeometryReader { proxy in
            let previewSize = previewSize(in: proxy.size)

            LazyVGrid(columns: [
              GridItem(.fixed(previewSize.width)),
              GridItem(.fixed(previewSize.width))
            ], spacing: 0) {
              ForEach(0 ..< store.homeButtons.count, id: \.self) { index in
                let homeButton = store.homeButtons[index]
                VStack {
                  Button(action: { store.send(.didTap(homeButton)) }) {
                    HomeButtonView(
                      size: previewSize,
                      homeButton: homeButton
                    )
                  }
                }
              }
              .frame(
                width: abs(previewSize.width),
                height: abs(previewSize.height + DesignConstants.padding)
              )
            }
            .padding(.top, DesignConstants.paddingXLarge)
            .padding(.bottom, DesignConstants.paddingXLarge)
          }
        }
        .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .navigationTitle(String(localized: "karmic_healing", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
      } destination: { store in
        switch store.case {
        case .balancingEnergyList(let store):
          BalancingEnergyListView(store: store)
        case .balancingEnergy(let store):
          BalancingEnergyView(store: store)
        case .requests(let store):
          RequestsView(store: store)
        case .reminders(let store):
          RemindersView(store: store)
        case .appSettings(let store):
          AppSettingsView(store: store)
        }
      }
    }
  }

  private func previewSize(in proxy: CGSize) -> CGSize {
    let width = (proxy.width - DesignConstants.itemSpacing) / 2
    let height = width * DesignConstants.goldenRatio
    return .init(width: width, height: height)
  }
}

#Preview {
  HomeView(store: .init(
    initialState: .init(),
    reducer: {
      Home()
    }
  ))
}

