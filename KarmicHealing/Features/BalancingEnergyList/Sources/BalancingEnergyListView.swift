//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Common
import Resources
import BalancingEnergy

public struct BalancingEnergyListView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss

  private let store: StoreOf<BalancingEnergyList>

  public init(store: StoreOf<BalancingEnergyList>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
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

        VStack {
          KarmicHealingDisclosureGroup {
            KarmicHealingDisclosureCell(String(localized: "initial_process", bundle: .main)) {
              self.store.send(.initialProcess)
            }

            KarmicHealingDisclosureCell(String(localized: "essential_self", bundle: .main)) {
              self.store.send(.essentialSelf)
            }

            KarmicHealingDisclosureCell(String(localized: "divine_self", bundle: .main)) {
              self.store.send(.divineSelf)
            }
          }

          Spacer()
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal)
        .padding(.top)
      }
      .navigationTitle(String(localized: "energy_balancing", bundle: .main))
      .navigationBarBackButtonHidden()
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
  BalancingEnergyListView(store: .init(
    initialState: .init(),
    reducer: {
      BalancingEnergyList()
    }
  ))
}

