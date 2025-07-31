//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct AppSettingsView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss

  let store: StoreOf<AppSettings>

  public init(store: StoreOf<AppSettings>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        GgWithGradientView()
        
        ScrollView {
          VStack {
            KarmicHealingDisclosureGroup {
              KarmicHealingDisclosureCell(String(localized: "about", bundle: .main)) {
                self.store.send(.didTapAbout)
              }

              KarmicHealingDisclosureCell(String(localized: "session_duration", bundle: .main)) {
                self.store.send(.didTapSessionDuration)
              }

              KarmicHealingDisclosureCell(String(localized: "change_language", bundle: .main)) {
                self.store.send(.didTapChangeLanguage)
              }

              KarmicHealingDisclosureCell(String(localized: "write_to_us", bundle: .main)) {
                self.store.send(.didTapContactEmail)
              }
            }
          }
        }
        .font(.headline.weight(.medium))
        .padding(.horizontal)
        .padding(.top)
      }
      .navigationTitle(String(localized: "settings", bundle: .main))
      .navigationBarBackButtonHidden()
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .onAppear {
        self.store.send(.onAppear)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          }
        }
      }
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.aboutAlert,
        action: Destination.Action.aboutAlert,
        content: KarmicHealingAlertView<Destination.Action.Alert>.init(store:)
      )
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.clipboardAlert,
        action: Destination.Action.clipboardAlert,
        content: KarmicHealingAlertView<Destination.Action.CopyAlert>.init(store:)
      )
      .fullScreenCover(
        store: self.store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.mailComposer,
        action: Destination.Action.mailComposer
      ) { store in
        MailComposerView(
          isShowing: Binding(
            get: { true },
            set: { if !$0 { self.store.send(.destination(.dismiss)) } }
          )
        )
      }
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.sessionDurationAlert,
        action: Destination.Action.sessionDurationAlert
      ) { _ in
        EnergyBalansingSettingsAlertView(store: store)
      }
    }
  }

}

#Preview {
  AppSettingsView(store: .init(
    initialState: .init(),
    reducer: {
      AppSettings()
    }
  ))
}

