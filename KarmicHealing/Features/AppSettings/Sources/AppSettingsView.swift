//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct AppSettingsView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @AppStorage(UserDefaultsClient.Keys.appLockEnabled) private var appLockEnabled = false
  @Dependency(\.passcode) private var passcode
  /// Read once rather than asked of the keychain on every redraw.
  @State private var hasPasscode = false
  @State private var isSettingPasscode = false

  @Bindable var store: StoreOf<AppSettings>

  public init(store: StoreOf<AppSettings>) {
    self.store = store
  }

  private var settingsContent: some View {
    ScrollView {
      VStack {
        KarmicHealingDisclosureGroup(content: {
          DisclosureCell("about".loc, tone: Spectrum.crown.color) {
            store.send(.didTapAbout)
          }

          DisclosureCell("theme".loc, tone: Spectrum.brow.color) {
            store.send(.didTapThemeSettings)
          }

          DisclosureCell("session_duration".loc, tone: Spectrum.brow.color) {
            store.send(.didTapSessionDuration)
          }

          DisclosureCell("change_language".loc, tone: Spectrum.brow.color) {
            store.send(.didTapChangeLanguage)
          }

          if Translation.isMachineTranslated {
            machineTranslationRow
          }

          appLockRow

          if appLockEnabled {
            DisclosureCell("passcode_change".loc, tone: Spectrum.brow.color) {
              isSettingPasscode = true
            }
          }

          DisclosureCell("privacy_policy".loc, tone: Spectrum.crown.color) {
            store.send(.didTapPrivacyPolicy)
          }

          DisclosureCell("write_to_us".loc, tone: Spectrum.brow.color) {
            store.send(.didTapContactEmail)
          }
        }, tone: Spectrum.brow.color)
      }
      // Inside the scroll content, not on the ScrollView: the card's shadow
      // needs room within the clipped bounds or it cuts off at the edges.
      .padding(.horizontal)
      .padding(.vertical)
      .karmicContentWidth()
    }
    .font(Typography.title)
  }

  /// Shown only where the words on screen came from a machine. It sits under the language row
  /// because that is where somebody who has just noticed a strange one will look, and it opens
  /// the same letter the "write to us" row does — the shortest path from noticing to telling.
  private var machineTranslationRow: some View {
    Button {
      store.send(.didTapContactEmail)
    } label: {
      HStack(spacing: DesignConstants.spacingMedium) {
        Image(systemName: "character.bubble")
          .font(Typography.icon)
          .foregroundStyle(AuraGradient.gradient(for: .throat))
          .frame(width: DesignConstants.frameHeightSmall)

        VStack(alignment: .leading, spacing: DesignConstants.paddingTiny) {
          Text("machine_translation_title".loc)
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          Text("machine_translation_note".loc)
            .font(Typography.caption)
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
            .fixedSize(horizontal: false, vertical: true)
        }
        .multilineTextAlignment(.leading)

        Spacer(minLength: DesignConstants.spacingSmall)

        Image(systemName: "envelope")
          .font(Typography.icon)
          .foregroundStyle(AuraGradient.gradient(for: .throat))
      }
      .frame(maxWidth: .infinity, minHeight: DesignConstants.frameHeightXXLarge)
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingSmall)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var appLockRow: some View {
    HStack(spacing: DesignConstants.spacingMedium) {
      Image(systemName: "lock.shield")
        .font(Typography.icon)
        .foregroundStyle(AuraGradient.gradient(for: .brow))
        .frame(width: DesignConstants.frameHeightSmall)

      VStack(alignment: .leading, spacing: DesignConstants.paddingTiny) {
        Text("app_lock".loc)
        Text("app_lock_description".loc)
          .font(Typography.caption)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      }

      Spacer(minLength: DesignConstants.spacingSmall)

      Toggle("app_lock".loc, isOn: appLockBinding)
        .labelsHidden()
        .tint(Spectrum.brow.color)
    }
    .frame(maxWidth: .infinity, minHeight: DesignConstants.frameHeightXXLarge)
    .padding(.horizontal, DesignConstants.paddingLarge)
  }

  /// Turning the lock on needs a code to fall back on when Face ID cannot answer, so the first
  /// switch of it goes through choosing one — and leaves the switch off if that is abandoned.
  private var appLockBinding: Binding<Bool> {
    Binding(
      get: { appLockEnabled },
      set: { isOn in
        guard isOn else {
          appLockEnabled = false
          return
        }
        if hasPasscode {
          appLockEnabled = true
        } else {
          isSettingPasscode = true
        }
      }
    )
  }

  private var settingsBase: some View {
    ZStack {
      AuraBackground(level: .brow)
      settingsContent
    }
    .navigationTitle("settings".loc)
    // The scroll sits under a full-bleed background, so the bar cannot track it: left on the
    // large title it drew one title in the bar and a second one over the rows.
    .navigationBarTitleDisplayMode(.inline)
    .navigationBarBackButtonHidden()
    .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
    .onAppear {
      store.send(.onAppear)
      hasPasscode = passcode.isSet()
    }
    .fullScreenCover(isPresented: $isSettingPasscode) {
      PasscodeSetupView(onFinished: {
        hasPasscode = true
        appLockEnabled = true
      })
    }
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button(action: { dismiss() }) {
          Image(systemName: "chevron.left")
            .renderingMode(.template)
            .foregroundStyle(AuraGradient.gradient(for: .brow))
        }
      }
    }
  }

  private func aboutAlertCover<Content: View>(_ content: Content) -> some View {
    content.fullScreenCover(
      item: $store.scope(\.destination?.aboutAlert, action: \.destination.aboutAlert),
      content: AlertView<Destination.Action.Alert>.init(store:)
    )
  }

  private func themeSettingsCover<Content: View>(_ content: Content) -> some View {
    content.fullScreenCover(
      item: $store.scope(\.destination?.themeSettings, action: \.destination.themeSettings)
    ) { store in
      ThemeSettingsView(store: store)
    }
  }

  private func sessionDurationCover<Content: View>(_ content: Content) -> some View {
    content.fullScreenCover(
      item: $store.scope(\.destination?.sessionDurationAlert, action: \.destination.sessionDurationAlert)
    ) { store in
      EnergyBalansingSettingsView(store: store)
    }
  }

  private func clipboardAlertCover<Content: View>(_ content: Content) -> some View {
    content.fullScreenCover(
      item: $store.scope(\.destination?.clipboardAlert, action: \.destination.clipboardAlert),
      content: AlertView<Destination.Action.CopyAlert>.init(store:)
    )
  }

  private func privacyPolicyCover<Content: View>(_ content: Content) -> some View {
    content.fullScreenCover(
      item: $store.scope(\.destination?.privacyPolicy, action: \.destination.privacyPolicy)
    ) { store in
      PrivacyPolicyView(store: store)
    }
  }

  private func mailComposerCover<Content: View>(_ content: Content) -> some View {
    content.fullScreenCover(
      item: $store.scope(\.destination?.mailComposer, action: \.destination.mailComposer)
    ) { _ in
      MailComposerView(
        isShowing: Binding(
          get: { true },
          set: { if !$0 { self.store.send(.destination(.dismiss)) } }
        )
      )
    }
  }

  public var body: some View {
    mailComposerCover(
      privacyPolicyCover(
        clipboardAlertCover(
          sessionDurationCover(
            themeSettingsCover(
              aboutAlertCover(settingsBase)
            )
          )
        )
      )
    )
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .brow)
    AppSettingsView(store: .init(
      initialState: .init(),
      reducer: {
        AppSettings()
      }
    ))
  }
}
