//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Resources
import Common
import AppSettings
import Requests
import BalancingEnergyList
import BalancingEnergy

public struct HomeView: View {
  @Bindable var store: StoreOf<Home>

  public init(store: StoreOf<Home>) {
    self.store = store
  }

  private struct ViewState: Equatable {
    init(state: Home.State) {}
  }

  public var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
        ZStack {
          ResourcesAsset.Colors.background.swiftUIColor
            .ignoresSafeArea()

          GeometryReader { proxy in
            let previewSize = previewSize(in: proxy.size)
            ScrollView {
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
                  height: abs(previewSize.height + 8)
                )
              }
              .padding(.top, 44)
              .padding(.bottom, 44)
            }
          }
        }
        .navigationBarBackgroundColor(ResourcesAsset.Colors.background.swiftUIColor)
        .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .navigationTitle(String(localized: "karmic_healing", bundle: .main))
        .navigationBarTitleDisplayMode(.inline)
      } destination: { store in
        switch store.case {
        case .appSettings(let store):
          AppSettingsView(store: store)
        case .requests(let store):
          RequestsView(store: store)
        case .balancingEnergyList(let store):
          BalancingEnergyListView(store: store)
        case .balancingEnergy(let store):
          BalancingEnergyView(store: store)
        }
      }
    }
  }

  private func previewSize(in proxy: CGSize) -> CGSize {
    let itemSpacing: CGFloat = 36
    let width = (proxy.width - itemSpacing) / 2
    let height = width * 0.615384615
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

