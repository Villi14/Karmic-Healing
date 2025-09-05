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
        BgWithGradientView()

        VStack {
          KarmicHealingDisclosureGroup {
            if !viewStore.initialProcessCompleted {
              DisclosureCell("initial_process".loc()) {
                self.store.send(.initialProcess)
              }
            }

            DisclosureCell("essential_self".loc()) {
              self.store.send(.essentialSelf)
            }

            DisclosureCell("divine_self".loc()) {
              self.store.send(.divineSelf)
            }
          }

          Spacer()
        }
        .font(.headline.weight(.medium))
        .padding(.horizontal)
        .padding(.top)
      }
      .onAppear { self.store.send(.onAppear) }
      .navigationTitle("energy_balancing".loc())
      .navigationBarBackButtonHidden()
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .sheet(isPresented: Binding(
        get: { viewStore.isHelpPresented },
        set: { isPresented in
          if !isPresented {
            store.send(.helpDismissed)
          }
        }
      )) {
        NavigationStack {
          BalancingEnergyHelpView()
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

