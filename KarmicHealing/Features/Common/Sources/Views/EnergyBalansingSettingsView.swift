//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources

@Reducer
public struct EnergyBalansingSettings {
  @Dependency(\.userDefaults) var userDefaults
  @Dependency(\.dismiss) var dismiss
  @Dependency(\.audio) var audio

  /// How long the screen stays lit after a step before it rests.
  public static let restDelayOptions = [15, 30, 60, 120]
  public static let defaultRestDelay = 30

  @ObservableState
  public struct State: Equatable {
    public var sessionDuration: Int
    public var soundEnabled: Bool
    public var vibrationEnabled: Bool
    public var audioVolume: Float
    public var screenRestEnabled: Bool
    public var screenRestDelay: Int

    public init(
      sessionDuration: Int = 5,
      soundEnabled: Bool = false,
      vibrationEnabled: Bool = false,
      audioVolume: Float = 0.5,
      screenRestEnabled: Bool = true,
      screenRestDelay: Int = EnergyBalansingSettings.defaultRestDelay
    ) {
      self.sessionDuration = sessionDuration
      self.soundEnabled = soundEnabled
      self.vibrationEnabled = vibrationEnabled
      self.audioVolume = audioVolume
      self.screenRestEnabled = screenRestEnabled
      self.screenRestDelay = screenRestDelay
    }
  }

  public enum Action: Equatable {
    case sessionDurationChanged(Int)
    case soundEnabledChanged(Bool)
    case vibrationEnabledChanged(Bool)
    case audioVolumeChanged(Float)
    case screenRestEnabledChanged(Bool)
    case screenRestDelayChanged(Int)
    case done
    case onAppear
  }

  public init() {}

  public var body: some ReducerOf<Self> {
    Reduce { (state: inout State, action: Action) in
      switch action {
      case let .sessionDurationChanged(duration):
        state.sessionDuration = duration
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(duration, for: .sessionDuration)
        }

      case let .soundEnabledChanged(enabled):
        state.soundEnabled = enabled
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(enabled, for: .soundEnabled)
        }

      case let .vibrationEnabledChanged(enabled):
        state.vibrationEnabled = enabled
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(enabled, for: .vibrationEnabled)
        }

      case let .audioVolumeChanged(volume):
        state.audioVolume = volume
        return .run { [userDefaults, audio] _ in
          await userDefaults.setAsync(volume, for: .audioVolume)
          audio.setVolume(volume)
        }

      case let .screenRestEnabledChanged(enabled):
        state.screenRestEnabled = enabled
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(enabled, for: .screenRestEnabled)
        }

      case let .screenRestDelayChanged(seconds):
        state.screenRestDelay = seconds
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(seconds, for: .screenRestDelay)
        }

      case .done:
        return .run { _ in
          await dismiss()
        }

      case .onAppear:
        let savedDuration = userDefaults.integer(for: .sessionDuration)
        state.sessionDuration = savedDuration > 0 ? savedDuration : 5 // Default to 5 minutes if not set

        // Screen rest is on out of the box — a meditation is meant to be done with eyes closed.
        state.screenRestEnabled = userDefaults.bool(for: .screenRestEnabled, default: true)
        let savedRestDelay = userDefaults.integer(for: .screenRestDelay)
        state.screenRestDelay = savedRestDelay > 0 ? savedRestDelay : Self.defaultRestDelay

        // Check if this is the first time opening settings
        let hasSoundSetting = userDefaults.object(for: .soundEnabled) != nil
        
        if !hasSoundSetting {
          // First time - set default values
          state.soundEnabled = false
          state.vibrationEnabled = false
          state.audioVolume = 0.5
          
          return .run { [userDefaults] _ in
            await userDefaults.setAsync(5, for: .sessionDuration)
            await userDefaults.setAsync(false, for: .soundEnabled)
            await userDefaults.setAsync(false, for: .vibrationEnabled)
            await userDefaults.setAsync(0.5, for: .audioVolume)
          }
        } else {
          // Load saved values
          state.soundEnabled = userDefaults.bool(for: .soundEnabled)
          state.vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
          state.audioVolume = userDefaults.float(for: .audioVolume)
          let volume = state.audioVolume
          return .run { [audio] _ in
            audio.setVolume(volume)
          }
        }
      }
    }
  }
}

public struct EnergyBalansingSettingsView: View {
  public let store: StoreOf<EnergyBalansingSettings>

  public init(store: StoreOf<EnergyBalansingSettings>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
        AuraBackground(level: .heart)
        
        ScrollView {
          VStack(spacing: DesignConstants.sectionSpacing) {
            titleView
            durationOptionsView(store)
            vibrationAndSoundSection(store)
            volumeSection(store)
            screenRestSection(store)
            doneButton(store)
          }
          .frame(maxWidth: DesignConstants.maxWidthMedium)
          .padding(.vertical, DesignConstants.screenVerticalPadding)
          .padding(.horizontal, DesignConstants.paddingXLarge)
          // The rows are already held to a phone's width above; the extra inset only has room
          // to spare on a tall screen. On a short one it squeezes "Session duration" onto two
          // lines and every row grows with it.
          .padding(.horizontal, DesignConstants.compact(DesignConstants.paddingXXLarge, 0))
          .frame(maxWidth: .infinity)
        }
        .onAppear {
          store.send(.onAppear)
        }
    }
  }

  private var titleView: some View {
    Text("settings".loc)
      .font(Typography.heading)
      .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
  }

  private func durationOptionsView(_ store: StoreOf<EnergyBalansingSettings>) -> some View {
    menuRow(
      icon: "clock",
      title: "session_duration".loc,
      options: Self.durationOptions,
      selection: store.sessionDuration,
      label: { "\($0) \("minutes".loc)" },
      onSelect: { store.send(.sessionDurationChanged($0)) }
    )
  }

  private static let durationOptions = [1, 3, 5, 10, 15]

  /// One card that opens the choices instead of laying them all out.
  ///
  /// Five durations and four delays stacked as rows pushed everything else on this screen below the
  /// fold, and the options are only ever looked at while one is being picked.
  private func menuRow(
    icon: String,
    title: String,
    options: [Int],
    selection: Int,
    label: @escaping (Int) -> String,
    onSelect: @escaping (Int) -> Void
  ) -> some View {
    HStack {
      Image(systemName: icon)
        .foregroundStyle(AuraGradient.gradient(for: .heart))

      Text(title)
        .font(Typography.body)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

      Spacer()

      Menu {
        // Checked rather than merely highlighted: a menu shows no selection of its own.
        ForEach(options, id: \.self) { option in
          Button(action: { onSelect(option) }) {
            if option == selection {
              Label(label(option), systemImage: "checkmark")
            } else {
              Text(label(option))
            }
          }
        }
      } label: {
        HStack(spacing: DesignConstants.spacingSmall) {
          Text(label(selection))
            .font(Typography.body)
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)

          Image(systemName: "chevron.up.chevron.down")
            .font(Typography.bodySecondary)
            .foregroundStyle(AuraGradient.gradient(for: .heart))
        }
      }
    }
    .padding(.horizontal, DesignConstants.paddingLarge)
    .padding(.vertical, DesignConstants.paddingMedium)
    .cardStyle(level: .heart, showsWatermark: false)
  }

  private func vibrationAndSoundSection(_ store: StoreOf<EnergyBalansingSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      HStack {
        Image(systemName: "iphone.radiowaves.left.and.right")
          .foregroundStyle(AuraGradient.gradient(for: .heart))

        Text("vibration".loc)
          .font(Typography.body)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

        Spacer()

        Toggle("", isOn: Binding(
          get: { store.vibrationEnabled },
          set: { store.send(.vibrationEnabledChanged($0)) }
        ))
        .toggleStyle(AuraSwitchToggleStyle(level: .heart))
        .accessibilityLabel("vibration".loc)
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .cardStyle(level: .heart, showsWatermark: false)

      HStack {
        Image(systemName: "speaker.wave.2")
          .foregroundStyle(AuraGradient.gradient(for: .heart))

        Text("sound".loc)
          .font(Typography.body)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

        Spacer()

        Toggle("", isOn: Binding(
          get: { store.soundEnabled },
          set: { store.send(.soundEnabledChanged($0)) }
        ))
        .toggleStyle(AuraSwitchToggleStyle(level: .heart))
        .accessibilityLabel("sound".loc)
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .cardStyle(level: .heart, showsWatermark: false)
    }
  }

  private func volumeSection(_ store: StoreOf<EnergyBalansingSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      HStack {
        Image(systemName: "speaker.wave.3")
            .foregroundStyle(store.soundEnabled ? AnyShapeStyle(AuraGradient.gradient(for: .heart)) : AnyShapeStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor))

        Text("volume".loc)
          .font(Typography.body)
          .foregroundStyle(store.soundEnabled ? ResourcesAsset.Colors.textPrimary.swiftUIColor : ResourcesAsset.Colors.textSecondary.swiftUIColor)

        Spacer()

        Text("\(Int(store.audioVolume * 100))%")
          .font(Typography.body)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .cardStyle(level: .heart, showsWatermark: false)

      AuraSlider(
        value: Binding(
          get: { store.audioVolume },
          set: { store.send(.audioVolumeChanged($0)) }
        ),
        in: 0.0...1.0,
        step: 0.1,
        level: .heart
      )
      .accessibilityLabel("volume".loc)
      .disabled(!store.soundEnabled)
      .padding(.horizontal, DesignConstants.paddingLarge)
    }
  }

  /// Darkening the screen between steps, and how long the step stays lit first.
  private func screenRestSection(_ store: StoreOf<EnergyBalansingSettings>) -> some View {
    VStack(spacing: DesignConstants.paddingMedium) {
      HStack {
        Image(systemName: "moon.stars")
          .foregroundStyle(AuraGradient.gradient(for: .heart))

        Text("screen_rest".loc)
          .font(Typography.body)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

        Spacer()

        Toggle("", isOn: Binding(
          get: { store.screenRestEnabled },
          set: { store.send(.screenRestEnabledChanged($0)) }
        ))
        .toggleStyle(AuraSwitchToggleStyle(level: .heart))
        .accessibilityLabel("screen_rest".loc)
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingMedium)
      .cardStyle(level: .heart, showsWatermark: false)

      if store.screenRestEnabled {
        menuRow(
          icon: "timer",
          title: "delay".loc,
          options: EnergyBalansingSettings.restDelayOptions,
          selection: store.screenRestDelay,
          label: { "seconds_count".loc($0) },
          onSelect: { store.send(.screenRestDelayChanged($0)) }
        )

        Text("screen_rest_hint".loc)
          .font(Typography.bodySecondary)
          .multilineTextAlignment(.center)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      }
    }
  }

  private func doneButton(_ store: StoreOf<EnergyBalansingSettings>) -> some View {
    Button {
      store.send(.done)
    } label: {
      Text("done".loc)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
    .buttonStyle(.karmic(level: .heart))
  }
}

/// A switch whose active track carries the same two-tone aura as the screen.
private struct AuraSwitchToggleStyle: ToggleStyle {
  let level: Spectrum

  func makeBody(configuration: Configuration) -> some View {
    Button {
      configuration.isOn.toggle()
    } label: {
      ZStack {
        Capsule()
          .fill(configuration.isOn
            ? AnyShapeStyle(AuraGradient.horizontal(for: level))
            : AnyShapeStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.28)))

        Circle()
          .fill(.white)
          .padding(2)
          .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
          .offset(x: configuration.isOn ? 10 : -10)
      }
      .frame(width: 51, height: 31)
      .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .animation(Motion.touch, value: configuration.isOn)
  }
}

/// A native-feeling slider with a gradient-filled progress track.
private struct AuraSlider: View {
  @Binding var value: Float

  let range: ClosedRange<Float>
  let step: Float
  let level: Spectrum

  @Environment(\.isEnabled) private var isEnabled

  init(
    value: Binding<Float>,
    in range: ClosedRange<Float>,
    step: Float,
    level: Spectrum
  ) {
    _value = value
    self.range = range
    self.step = step
    self.level = level
  }

  var body: some View {
    GeometryReader { proxy in
      let thumbDiameter: CGFloat = 28
      let availableWidth = max(proxy.size.width - thumbDiameter, 1)
      let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
      let thumbX = thumbDiameter / 2 + availableWidth * min(max(progress, 0), 1)

      ZStack(alignment: .leading) {
        Capsule()
          .fill(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.20))
          .frame(height: 6)
          .padding(.horizontal, thumbDiameter / 2)

        Capsule()
          .fill(AuraGradient.horizontal(for: level))
          .frame(width: availableWidth * min(max(progress, 0), 1), height: 6)
          .padding(.leading, thumbDiameter / 2)

        Circle()
          .fill(.white)
          .overlay {
            Circle()
              .stroke(AuraGradient.gradient(for: level), lineWidth: 2)
          }
          .shadow(color: .black.opacity(0.16), radius: 3, y: 1)
          .frame(width: thumbDiameter, height: thumbDiameter)
          .position(x: thumbX, y: proxy.size.height / 2)
      }
      .contentShape(Rectangle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { gesture in
            guard isEnabled else { return }
            updateValue(for: gesture.location.x, availableWidth: availableWidth, thumbDiameter: thumbDiameter)
          }
      )
    }
    .frame(height: 32)
    .opacity(isEnabled ? 1 : DesignConstants.opacityMedium)
    .accessibilityRepresentation {
      Slider(value: $value, in: range, step: step)
    }
  }

  private func updateValue(
    for location: CGFloat,
    availableWidth: CGFloat,
    thumbDiameter: CGFloat
  ) {
    let progress = min(max((location - thumbDiameter / 2) / availableWidth, 0), 1)
    let rawValue = range.lowerBound + Float(progress) * (range.upperBound - range.lowerBound)
    let steppedValue = range.lowerBound
      + ((rawValue - range.lowerBound) / step).rounded() * step
    value = min(max(steppedValue, range.lowerBound), range.upperBound)
  }
}
