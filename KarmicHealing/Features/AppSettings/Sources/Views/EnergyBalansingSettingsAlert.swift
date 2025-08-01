// Karmic Healing 2025

import ComposableArchitecture
import Common
import UIKit
import SwiftUI
import Resources

@ObservableState
public struct EnergyBalansingSettingsAlertState: Equatable {
  var currentDuration: Int
  var soundEnabled: Bool
  var vibrationEnabled: Bool

  public init(currentDuration: Int, soundEnabled: Bool = true, vibrationEnabled: Bool = true) {
    self.currentDuration = currentDuration
    self.soundEnabled = soundEnabled
    self.vibrationEnabled = vibrationEnabled
  }
}

public enum EnergyBalansingSettingsAlertAction: Equatable {
  case durationSelected(Int)
  case soundToggled(Bool)
  case vibrationToggled(Bool)
  case dismiss
}

public struct EnergyBalansingSettingsAlertView: View {
  let store: StoreOf<AppSettings>

  public init(store: StoreOf<AppSettings>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        GgWithGradientView()

        VStack(spacing: DesignConstants.spacingLarge) {
          titleView
          durationOptionsView(viewStore)
          soundAndVibrationSection(viewStore)
          doneButton(viewStore)
        }
        .frame(maxWidth: DesignConstants.maxWidthMedium)
        .padding(DesignConstants.paddingXLarge)
        .padding(.horizontal, DesignConstants.paddingXXLarge)
      }
    }
  }

  private var titleView: some View {
    Text(String(localized: "session_duration", bundle: .main))
      .font(.headline.weight(.semibold))
      .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
  }

  private func durationOptionsView(_ viewStore: ViewStoreOf<AppSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      ForEach([1, 3, 5, 10, 15], id: \.self) { duration in
        durationButton(duration: duration, isSelected: viewStore.sessionDuration == duration, viewStore: viewStore)
      }
    }
  }

  private func durationButton(duration: Int, isSelected: Bool, viewStore: ViewStoreOf<AppSettings>) -> some View {
    Button(action: {
      viewStore.send(.sessionDurationChanged(duration))
    }) {
      HStack {
        Text("\(duration) \(duration == 1 ? String(localized: "minute", bundle: .main) : String(localized: "minutes", bundle: .main))")
          .font(.body)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)

        } else {
          Image(systemName: "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(ResourcesAsset.Colors.health.swiftUIColor)
        }
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.padding)
      .background(
        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
      )
    }
  }

  private func soundAndVibrationSection(_ viewStore: ViewStoreOf<AppSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
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
      .background(
        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
      )
      
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
      .background(
        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
      )
    }
  }

  private func doneButton(_ viewStore: ViewStoreOf<AppSettings>) -> some View {
    Button(action: {
      viewStore.send(.destination(.dismiss))
    }) {
      Text(String(localized: "done", bundle: .main))
        .font(.body.weight(.semibold))
        .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
        .frame(maxWidth: DesignConstants.maxWidthMedium)
        .frame(maxHeight: DesignConstants.frameHeightLarge)
        .background(
          RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
            .fill(ResourcesAsset.Colors.clam.swiftUIColor)
        )
        .padding(.vertical, DesignConstants.paddingMedium)
    }
  }
}

