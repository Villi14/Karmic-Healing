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
        BgWithGradientView()

        ScrollView {
          VStack {
            KarmicHealingDisclosureGroup {
              DisclosureCell(String(localized: "about", bundle: .main)) {
                self.store.send(.didTapAbout)
              }

              DisclosureCell(String(localized: "theme", bundle: .main)) {
                self.store.send(.didTapThemeSettings)
              }

              DisclosureCell(String(localized: "session_duration", bundle: .main)) {
                self.store.send(.didTapSessionDuration)
              }

              DisclosureCell(String(localized: "change_language", bundle: .main)) {
                self.store.send(.didTapChangeLanguage)
              }

              DisclosureCell(String(localized: "write_to_us", bundle: .main)) {
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
        state: \.clipboardAlert,
        action: Destination.Action.clipboardAlert,
        content: AlertView<Destination.Action.CopyAlert>.init(store:)
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
      ) { store in
        EnergyBalansingSettingsView(store: store)
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

