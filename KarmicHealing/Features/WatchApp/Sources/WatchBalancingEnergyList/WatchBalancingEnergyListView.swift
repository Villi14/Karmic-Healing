//
//   Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Foundation

public struct WatchBalancingEnergyListView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @AppStorage("user_language") private var userLanguage: String = "en"
  
  @Bindable var store: StoreOf<WatchBalancingEnergyList>
  
  public init(store: StoreOf<WatchBalancingEnergyList>) {
    self.store = store
  }
  
  public var body: some View {
    NavigationStack {
      ZStack {
        KarmicHealingWatchAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()
        
        ScrollView {
          VStack(spacing: DesignConstants.spacing) {
            ActionButtonView(text: "essential_self".localized(for: Locale(identifier: userLanguage))) {
              store.send(.essentialSelf)
            }
            
            ActionButtonView(text: "divine_self".localized(for: Locale(identifier: userLanguage))) {
              store.send(.divineSelf)
            }
            
            ActionButtonView(text: "settings".localized(for: Locale(identifier: userLanguage))) {
              store.send(.openSettings)
            }
          }
          .padding(.horizontal, DesignConstants.paddingSmall)
          .padding(.vertical, DesignConstants.paddingTiny)
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
    .fullScreenCover(item: $store.scope(state: \.balancingEnergy, action: \.balancingEnergy)) { balancingEnergyStore in
      WatchBalancingEnergyView(store: balancingEnergyStore)
    }
    .fullScreenCover(item: $store.scope(state: \.settings, action: \.settings)) { settingsStore in
      WatchSettingsView(store: settingsStore)
    }
  }
  
  private struct ActionButtonView: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
      Text(text)
        .font(.caption2.bold())
        .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignConstants.padding)
        .padding(.horizontal, DesignConstants.paddingMedium)
        .background(KarmicHealingWatchAsset.Colors.cellBackground.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cornerRadius))
        .onTapGesture {
          action()
        }
    }
  }
  
  // Label-only version without gesture to be used inside NavigationLink
  private struct ActionButtonLabel: View {
    let text: String
    
    var body: some View {
      Text(text)
        .font(.caption2.bold())
        .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignConstants.padding)
        .padding(.horizontal, DesignConstants.paddingMedium)
        .background(KarmicHealingWatchAsset.Colors.cellBackground.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cornerRadius))
    }
  }
}

#Preview {
  WatchBalancingEnergyListView(store: .init(
    initialState: .init(),
    reducer: {
      WatchBalancingEnergyList()
    }
  ))
}
