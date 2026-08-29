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
      AuraBackground(level: .heart)

      VStack {
        KarmicHealingDisclosureGroup(content: {
          if !store.initialProcessCompleted {
            DisclosureCell("initial_process".loc, tone: Spectrum.heart.color) {
              store.send(.initialProcess)
            }
          }

          DisclosureCell("essential_self".loc, tone: Spectrum.heart.color) {
            store.send(.essentialSelf)
          }

          DisclosureCell("divine_self".loc, tone: Spectrum.heart.color) {
            store.send(.divineSelf)
          }
        }, tone: Spectrum.heart.color)

        Spacer()
      }
      .font(Typography.title)
      .padding(.horizontal)
      .padding(.top)
      .karmicContentWidth()
    }
    .onAppear { store.send(.onAppear) }
    .navigationTitle("energy_balancing".loc)
    .navigationBarTitleDisplayMode(.inline)
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
            .foregroundStyle(AuraGradient.gradient(for: .heart))
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        Button(action: { store.send(.helpButtonTapped) }) {
          Image(systemName: "questionmark.circle")
            .foregroundStyle(AuraGradient.gradient(for: .heart))
        }
      }
    }
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .heart)
    BalancingEnergyListView(store: .init(
      initialState: .init(),
      reducer: {
        BalancingEnergyList()
      }
    ))
  }
}
