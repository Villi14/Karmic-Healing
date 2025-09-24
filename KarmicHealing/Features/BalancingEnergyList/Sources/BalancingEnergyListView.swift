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

  @Bindable var store: StoreOf<BalancingEnergyList>

  public init(store: StoreOf<BalancingEnergyList>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      BgWithGradientView()

      VStack {
        KarmicHealingDisclosureGroup {
          if !store.initialProcessCompleted {
            DisclosureCell("initial_process".loc) {
              store.send(.initialProcess)
            }
          }

          DisclosureCell("essential_self".loc) {
            store.send(.essentialSelf)
          }

          DisclosureCell("divine_self".loc) {
            store.send(.divineSelf)
          }
        }

        Spacer()
      }
      .font(.headline.weight(.medium))
      .padding(.horizontal)
      .padding(.top)
    }
    .onAppear { store.send(.onAppear) }
    .navigationTitle("energy_balancing".loc)
    .navigationBarBackButtonHidden()
    .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
    .sheet(item: $store.scope(state: \.help, action: \.help)) { helpStore in
      NavigationStack {
        BalancingEnergyHelpView(store: helpStore)
      }
      .presentationDetents([.large])
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .renderingMode(.template)
            .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: { store.send(.helpButtonTapped) }) {
          Image(systemName: "questionmark.circle")
            .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        }
      }
    }
  }
}

#Preview {
  ZStack {
    BgWithGradientView()
    BalancingEnergyListView(store: .init(
      initialState: .init(),
      reducer: {
        BalancingEnergyList()
      }
    ))
  }
}

