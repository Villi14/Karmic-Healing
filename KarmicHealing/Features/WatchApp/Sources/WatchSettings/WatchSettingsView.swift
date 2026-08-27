//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture

public struct WatchSettingsView: View {
  @Bindable var store: StoreOf<WatchSettings>
  @AppStorage("user_language") private var userLanguage: String = "en"

  public init(store: StoreOf<WatchSettings>) {
    self.store = store
  }

  static let supportedLanguages = [
    "en", "uk", "ru", "es", "pt-BR", "fr", "de", "it", "pl", "tr", "zh-Hans", "ja", "ko", "hi", "bn"
  ]

  /// Each language is listed in its own words, the way the system language picker does it —
  /// a reader looking for their language finds it without knowing the current one.
  static func languageName(_ identifier: String) -> String {
    let locale = Locale(identifier: identifier)
    let name = locale.localizedString(forIdentifier: identifier) ?? identifier
    return name.prefix(1).uppercased(with: locale) + name.dropFirst()
  }

  public var body: some View {
    NavigationView {
      ZStack {
        KarmicHealingWatchAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()

        List {
          Section {
            HStack {
              Image(systemName: "speaker.wave.2")
                .foregroundColor(Spectrum.brow.color)
              
              if store.soundEnabled {
                Spacer()
                Text("\(Int(store.audioVolume * 100))%")
                  .foregroundColor(KarmicHealingWatchAsset.Colors.textSecondary.swiftUIColor)
                  .font(.caption)
              }

              Toggle("", isOn: Binding(
                get: { store.soundEnabled },
                set: { _ in store.send(.toggleSound) }
              ))
              .tint(Spectrum.brow.color)
            }

            if store.soundEnabled {
              Slider(
                value: Binding(
                  get: { store.audioVolume },
                  set: { store.send(.setAudioVolume($0)) }
                ),
                in: 0...1,
                step: 0.1
              )
              .tint(Spectrum.brow.color)
            }
          } header: {
            Text("sound".localized(for: Locale(identifier: userLanguage)))
              .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
              .font(Typography.label)
          }

          Section {
            // A row that pushes the choices rather than stacking five of them: on a screen this
            // narrow the durations alone used to fill it end to end.
            Picker(selection: Binding(
              get: { store.sessionDuration },
              set: { store.send(.setSessionDuration($0)) }
            )) {
              ForEach([1, 3, 5, 10, 15], id: \.self) { duration in
                Text("\(duration) \("min".localized(for: Locale(identifier: userLanguage)))")
                  .tag(duration)
              }
            } label: {
              Label {
                Text("duration".localized(for: Locale(identifier: userLanguage)))
                  .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
              } icon: {
                Image(systemName: "clock")
                  .foregroundColor(Spectrum.brow.color)
              }
            }
            .pickerStyle(.navigationLink)
          }

          Section {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "globe")
                  .foregroundColor(Spectrum.brow.color)
                Spacer()
              }

              VStack(spacing: 8) {
                ForEach(Self.supportedLanguages, id: \.self) { language in
                  SettingsButtonLabel(text: Self.languageName(language), isSelected: store.userLanguage == language)
                    .onTapGesture {
                      store.send(.setUserLanguage(language))
                    }
                }
              }
            }
            // Language is the last thing on this screen, and the last plate used to sit right on
            // the bottom edge — hard to read and harder to hit where the glass curves away.
            .padding(.bottom, DesignConstants.watchSettingsBottomPadding)
          } header: {
            Text("language".localized(for: Locale(identifier: userLanguage)))
              .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
              .font(Typography.label)
          }

        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
          store.send(.onAppear)
        }
      }
    }
  }
}


// Label-only settings button that matches ActionButtonView in WatchBalancingEnergyListView
private struct SettingsButtonLabel: View {
  let text: String
  let isSelected: Bool

  var body: some View {
    Text(text)
      .font(Typography.cardTitle)
      .foregroundColor(
        isSelected
        ? KarmicHealingWatchAsset.Colors.textInvert.swiftUIColor
        : KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor
      )
      .frame(maxWidth: .infinity)
      .padding(.vertical, DesignConstants.padding)
      .padding(.horizontal, DesignConstants.paddingMedium)
      .background(isSelected ? Spectrum.brow.color : KarmicHealingWatchAsset.Colors.cellBackground.swiftUIColor)
      .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusLarge, style: .continuous))
      .animation(Motion.touch, value: isSelected)
  }
}

#Preview {
  WatchSettingsView(store: Store(
    initialState: WatchSettings.State(),
    reducer: { WatchSettings() }
  ))
}
