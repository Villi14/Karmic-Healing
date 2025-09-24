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

  private var settingsContent: some View {
    ScrollView {
      VStack {
        KarmicHealingDisclosureGroup {
          DisclosureCell("about".loc) {
            store.send(.didTapAbout)
          }

          DisclosureCell("theme".loc) {
            store.send(.didTapThemeSettings)
          }

          DisclosureCell("session_duration".loc) {
            store.send(.didTapSessionDuration)
          }

          DisclosureCell("change_language".loc) {
            store.send(.didTapChangeLanguage)
          }

          DisclosureCell("privacy_policy".loc) {
            store.send(.didTapPrivacyPolicy)
          }

          DisclosureCell("write_to_us".loc) {
            store.send(.didTapContactEmail)
          }
        }
      }
    }
    .font(.headline.weight(.medium))
    .padding(.horizontal)
    .padding(.top)
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        BgWithGradientView()
        settingsContent
      }
      .navigationTitle("settings".loc)
      .navigationBarBackButtonHidden()
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .onAppear {
        viewStore.send(.onAppear)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
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
        content: AlertView<Destination.Action.Alert>.init(store:)
      )
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.themeSettings,
        action: Destination.Action.themeSettings
      ) { store in
        ThemeSettingsView(store: store)
      }
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.sessionDurationAlert,
        action: Destination.Action.sessionDurationAlert
      ) { store in
        EnergyBalansingSettingsView(store: store)
      }
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.clipboardAlert,
        action: Destination.Action.clipboardAlert,
        content: AlertView<Destination.Action.CopyAlert>.init(store:)
      )
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.privacyPolicy,
        action: Destination.Action.privacyPolicy
      ) { store in
        PrivacyPolicyView(store: store)
      }
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.mailComposer,
        action: Destination.Action.mailComposer
      ) { store in
        MailComposerView(
          isShowing: Binding(
            get: { true },
            set: { if !$0 { viewStore.send(.destination(.dismiss)) } }
          )
        )
      }
    }
  }
}

#Preview {
  ZStack {
    BgWithGradientView()
    AppSettingsView(store: .init(
      initialState: .init(),
      reducer: {
        AppSettings()
      }
    ))
  }
}

