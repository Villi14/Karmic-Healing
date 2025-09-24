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

  public var body: some View {
    NavigationView {
      ZStack {
        KarmicHealingWatchAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()

        List {
          Section {
            HStack {
              Image(systemName: "speaker.wave.2")
                .foregroundColor(KarmicHealingWatchAsset.Colors.friendly.swiftUIColor)
              
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
              .tint(KarmicHealingWatchAsset.Colors.health.swiftUIColor)
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
              .tint(KarmicHealingWatchAsset.Colors.health.swiftUIColor)
            }
          } header: {
            Text("sound".localized(for: Locale(identifier: userLanguage)))
              .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
              .font(.caption.bold())
          }

          Section {
            HStack {
              Image(systemName: "iphone.radiowaves.left.and.right")
                .foregroundColor(KarmicHealingWatchAsset.Colors.friendly.swiftUIColor)
              Toggle("", isOn: Binding(
                get: { store.vibrationEnabled },
                set: { _ in store.send(.toggleVibration) }
              ))
              .tint(KarmicHealingWatchAsset.Colors.health.swiftUIColor)
            }
          } header: {
            Text("vibration".localized(for: Locale(identifier: userLanguage)))
              .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
              .font(.caption.bold())
          }

          Section {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "clock")
                  .foregroundColor(KarmicHealingWatchAsset.Colors.friendly.swiftUIColor)
                Spacer()
              }

              VStack(spacing: 8) {
                ForEach([1, 3, 5, 10, 15], id: \.self) { duration in
                  SettingsButtonLabel(text: "\(duration) \("min".localized(for: Locale(identifier: userLanguage)))", isSelected: store.sessionDuration == duration)
                    .onTapGesture { 
                      store.send(.setSessionDuration(duration)) 
                    }
                }
              }
            }
          } header: {
            Text("duration".localized(for: Locale(identifier: userLanguage)))
              .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
              .font(.caption.bold())
          }

          Section {
            VStack(alignment: .leading, spacing: 8) {
              HStack {
                Image(systemName: "globe")
                  .foregroundColor(KarmicHealingWatchAsset.Colors.friendly.swiftUIColor)
                Spacer()
              }

              VStack(spacing: 8) {
                ForEach(["en", "uk", "ru"], id: \.self) { language in
                  SettingsButtonLabel(text: language.localized(for: Locale(identifier: userLanguage)), isSelected: store.userLanguage == language)
                    .onTapGesture { 
                      store.send(.setUserLanguage(language))
                    }
                }
              }
            }
          } header: {
            Text("language".localized(for: Locale(identifier: userLanguage)))
              .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
              .font(.caption.bold())
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
      .font(.caption2.bold())
      .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
      .frame(maxWidth: .infinity)
      .padding(.vertical, DesignConstants.padding)
      .padding(.horizontal, DesignConstants.paddingMedium)
      .background(isSelected ? KarmicHealingWatchAsset.Colors.clam.swiftUIColor : KarmicHealingWatchAsset.Colors.cellBackground.swiftUIColor)
      .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cornerRadius))
  }
}

#Preview {
  WatchSettingsView(store: Store(
    initialState: WatchSettings.State(),
    reducer: { WatchSettings() }
  ))
}
