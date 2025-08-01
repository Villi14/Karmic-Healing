//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources

public struct EnergyBalansingSettingsView: View {
  public let store: StoreOf<EnergyBalansingSettings>

  public init(store: StoreOf<EnergyBalansingSettings>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: DesignConstants.spacingLarge) {
        titleView
        durationOptionsView(viewStore)
        vibrationAndSoundSection(viewStore)
        volumeSection(viewStore)
        doneButton(viewStore)
      }
      .frame(maxWidth: DesignConstants.maxWidthMedium)
      .padding(DesignConstants.paddingXLarge)
      .padding(.horizontal, DesignConstants.paddingXXLarge)
      .onAppear {
        viewStore.send(.onAppear)
      }
    }
  }

  private var titleView: some View {
    Text(String(localized: "session_duration", bundle: .main))
      .font(.title2.weight(.semibold))
      .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
  }

  private func durationOptionsView(_ viewStore: ViewStoreOf<EnergyBalansingSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      ForEach([1, 3, 5, 10, 15], id: \.self) { duration in
        durationButton(duration: duration, isSelected: viewStore.sessionDuration == duration, viewStore: viewStore)
      }
    }
  }

  private func durationButton(duration: Int, isSelected: Bool, viewStore: ViewStoreOf<EnergyBalansingSettings>) -> some View {
    Button(action: {
      viewStore.send(.sessionDurationChanged(duration))
    }) {
      HStack {
        Text("\(duration) \(String(localized: "minutes", bundle: .main))")
          .font(.body)
          .foregroundStyle(isSelected ? ResourcesAsset.Colors.textPrimary.swiftUIColor : ResourcesAsset.Colors.textSecondary.swiftUIColor)
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)
        }
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .background(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium).fill(ResourcesAsset.Colors.cellBackground.swiftUIColor))
    }
  }

  private func vibrationAndSoundSection(_ viewStore: ViewStoreOf<EnergyBalansingSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      HStack {
        Image(systemName: "iphone.radiowaves.left.and.right")
          .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)

        Text(String(localized: "vibration", bundle: .main))
          .font(.body)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

        Spacer()

        Toggle("", isOn: Binding(
          get: { viewStore.vibrationEnabled },
          set: { viewStore.send(.vibrationEnabledChanged($0)) }
        ))
        .toggleStyle(SwitchToggleStyle(tint: ResourcesAsset.Colors.health.swiftUIColor))
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .background(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium).fill(ResourcesAsset.Colors.cellBackground.swiftUIColor))

      HStack {
        Image(systemName: "speaker.wave.2.fill")
          .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)

        Text(String(localized: "sound", bundle: .main))
          .font(.body)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

        Spacer()

        Toggle("", isOn: Binding(
          get: { viewStore.soundEnabled },
          set: { viewStore.send(.soundEnabledChanged($0)) }
        ))
        .toggleStyle(SwitchToggleStyle(tint: ResourcesAsset.Colors.health.swiftUIColor))
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .background(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium).fill(ResourcesAsset.Colors.cellBackground.swiftUIColor))
    }
  }

  private func volumeSection(_ viewStore: ViewStoreOf<EnergyBalansingSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      HStack {
        Image(systemName: "speaker.wave.3.fill")
          .foregroundStyle(viewStore.soundEnabled ? ResourcesAsset.Colors.friendly.swiftUIColor : ResourcesAsset.Colors.textSecondary.swiftUIColor)

        Text(String(localized: "volume", bundle: .main))
          .font(.body)
          .foregroundStyle(viewStore.soundEnabled ? ResourcesAsset.Colors.textPrimary.swiftUIColor : ResourcesAsset.Colors.textSecondary.swiftUIColor)

        Spacer()

        Text("\(Int(viewStore.audioVolume * 100))%")
          .font(.body)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .background(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium).fill(ResourcesAsset.Colors.cellBackground.swiftUIColor))

      Slider(
        value: Binding(
          get: { viewStore.audioVolume },
          set: { viewStore.send(.audioVolumeChanged($0)) }
        ),
        in: 0.0...1.0,
        step: 0.1
      )
      .accentColor(ResourcesAsset.Colors.health.swiftUIColor)
      .disabled(!viewStore.soundEnabled)
      .padding(.horizontal, DesignConstants.paddingLarge)
    }
  }

  private func doneButton(_ viewStore: ViewStoreOf<EnergyBalansingSettings>) -> some View {
    Button(action: {
      viewStore.send(.done)
    }) {
      Text(String(localized: "done", bundle: .main))
        .font(.headline.weight(.semibold))
        .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignConstants.paddingLarge)
        .background(
          RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
            .fill(ResourcesAsset.Colors.clam.swiftUIColor)
        )
    }
  }
}
