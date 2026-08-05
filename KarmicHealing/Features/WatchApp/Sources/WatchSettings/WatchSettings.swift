//
// Karmic Healing 2025
//

import ComposableArchitecture
import Foundation
import OSLog

@Reducer
public struct WatchSettings {
  @Dependency(\.watchUserDefaults) var userDefaults
  
  public init() {}

  /// Seconds of stillness the user can choose from before the screen rests.
  public static let restDelayOptions = [15, 30, 60, 120]

  @ObservableState
  public struct State: Equatable {
    public var soundEnabled: Bool
    public var vibrationEnabled: Bool
    public var audioVolume: Float
    public var sessionDuration: Int
    public var userLanguage: String
    public var screenRestEnabled: Bool
    public var screenRestDelay: Int

    public init(
      soundEnabled: Bool = false,
      vibrationEnabled: Bool = false,
      audioVolume: Float = 0.5,
      sessionDuration: Int = 5,
      userLanguage: String = "en",
      screenRestEnabled: Bool = true,
      screenRestDelay: Int = WatchBalancingEnergy.defaultRestDelay
    ) {
      self.soundEnabled = soundEnabled
      self.vibrationEnabled = vibrationEnabled
      self.audioVolume = audioVolume
      self.sessionDuration = sessionDuration
      self.userLanguage = userLanguage
      self.screenRestEnabled = screenRestEnabled
      self.screenRestDelay = screenRestDelay
    }

    // Static method to create state with loaded settings
    public static func withLoadedSettings(userDefaults: WatchUserDefaultsClient) -> State {
      let soundEnabled = userDefaults.bool(for: .soundEnabled)
      let vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
      let audioVolume = userDefaults.float(for: .audioVolume) == 0.0 ? 0.5 : userDefaults.float(for: .audioVolume)
      let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
      let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
      let userLanguage = userDefaults.string(for: .userLanguage) ?? "en"
      let screenRestEnabled = userDefaults.bool(for: .screenRestEnabled, default: true)
      let rawRestDelay = userDefaults.integer(for: .screenRestDelay)

      return State(
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        audioVolume: audioVolume,
        sessionDuration: sessionDuration,
        userLanguage: userLanguage,
        screenRestEnabled: screenRestEnabled,
        screenRestDelay: rawRestDelay > 0 ? rawRestDelay : WatchBalancingEnergy.defaultRestDelay
      )
    }
  }
  
  public enum Action: Equatable {
    case onAppear
    case loadSettings(soundEnabled: Bool, vibrationEnabled: Bool, audioVolume: Float, sessionDuration: Int, userLanguage: String)
    case loadScreenRest(enabled: Bool, delay: Int)
    case toggleSound
    case toggleVibration
    case setAudioVolume(Float)
    case setSessionDuration(Int)
    case setUserLanguage(String)
    /// Carries the new value rather than flipping in place, so the running session can follow it.
    case toggleScreenRest(Bool)
    case setScreenRestDelay(Int)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          // Load current settings from UserDefaults
          let soundEnabled = userDefaults.bool(for: .soundEnabled)
          let vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
          let rawAudioVolume = userDefaults.float(for: .audioVolume)
          // Use saved volume if it exists, otherwise use 0.0 (will be set to 0.5 when enabling sound)
          let audioVolume = rawAudioVolume
          let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
          let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
          let userLanguage = userDefaults.string(for: .userLanguage) ?? "en"
          
          Log.settings.debug(
            """
            Loaded settings — sound: \(soundEnabled, privacy: .public), \
            vibration: \(vibrationEnabled, privacy: .public), \
            volume: \(audioVolume, privacy: .public), \
            duration: \(sessionDuration, privacy: .public) min, \
            language: \(userLanguage, privacy: .public)
            """
          )

          await send(.loadSettings(
            soundEnabled: soundEnabled,
            vibrationEnabled: vibrationEnabled,
            audioVolume: audioVolume,
            sessionDuration: sessionDuration,
            userLanguage: userLanguage
          ))

          let rawRestDelay = userDefaults.integer(for: .screenRestDelay)
          await send(.loadScreenRest(
            enabled: userDefaults.bool(for: .screenRestEnabled, default: true),
            delay: rawRestDelay > 0 ? rawRestDelay : WatchBalancingEnergy.defaultRestDelay
          ))
        }

      case let .loadScreenRest(enabled, delay):
        state.screenRestEnabled = enabled
        state.screenRestDelay = delay
        return .none

      case let .loadSettings(soundEnabled, vibrationEnabled, audioVolume, sessionDuration, userLanguage):
        state.soundEnabled = soundEnabled
        state.vibrationEnabled = vibrationEnabled
        state.audioVolume = audioVolume
        state.sessionDuration = sessionDuration
        state.userLanguage = userLanguage
        return .none
        
      case .toggleSound:
        state.soundEnabled.toggle()
        
        if state.soundEnabled {
          // When enabling sound, restore previous volume or use 0.5 if none saved
          let savedVolume = userDefaults.float(for: .audioVolume)
          state.audioVolume = savedVolume > 0.0 ? savedVolume : 0.5
        }
        let soundEnabled = state.soundEnabled
        let audioVolume = state.audioVolume
        Log.settings.debug(
          "Sound \(soundEnabled ? "enabled" : "disabled", privacy: .public), volume \(audioVolume, privacy: .public)"
        )

        return .run { [state] send in
          await userDefaults.setAsync(state.soundEnabled, for: .soundEnabled)
          if state.soundEnabled {
            await userDefaults.setAsync(state.audioVolume, for: .audioVolume)
          }
        }
        
      case .toggleVibration:
        state.vibrationEnabled.toggle()
        return .run { [state] send in
          await userDefaults.setAsync(state.vibrationEnabled, for: .vibrationEnabled)
        }
        
      case let .setAudioVolume(volume):
        state.audioVolume = volume
        Log.settings.debug("Audio volume set to \(volume, privacy: .public)")
        return .run { [state] send in
          await userDefaults.setAsync(state.audioVolume, for: .audioVolume)
        }
        
      case let .setSessionDuration(duration):
        state.sessionDuration = duration
        return .run { [state] send in
          await userDefaults.setAsync(state.sessionDuration, for: .sessionDuration)
        }
        
      case let .toggleScreenRest(enabled):
        state.screenRestEnabled = enabled
        Log.settings.debug("Screen rest \(enabled ? "enabled" : "disabled", privacy: .public)")
        return .run { _ in
          await userDefaults.setAsync(enabled, for: .screenRestEnabled)
        }

      case let .setScreenRestDelay(seconds):
        state.screenRestDelay = seconds
        return .run { _ in
          await userDefaults.setAsync(seconds, for: .screenRestDelay)
        }

      case let .setUserLanguage(language):
        state.userLanguage = language
        return .run { [state] send in
          await userDefaults.setAsync(state.userLanguage, for: .userLanguage)
          // Also update @AppStorage for immediate UI update
          await MainActor.run {
            UserDefaults.standard.set(state.userLanguage, forKey: "user_language")
          }
        }
      }
    }
  }
}
