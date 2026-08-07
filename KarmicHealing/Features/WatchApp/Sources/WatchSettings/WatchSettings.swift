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

  @ObservableState
  public struct State: Equatable {
    public var soundEnabled: Bool
    public var audioVolume: Float
    public var sessionDuration: Int
    public var userLanguage: String

    public init(
      soundEnabled: Bool = false,
      audioVolume: Float = 0.5,
      sessionDuration: Int = 5,
      userLanguage: String = "en"
    ) {
      self.soundEnabled = soundEnabled
      self.audioVolume = audioVolume
      self.sessionDuration = sessionDuration
      self.userLanguage = userLanguage
    }

    // Static method to create state with loaded settings
    public static func withLoadedSettings(userDefaults: WatchUserDefaultsClient) -> State {
      let soundEnabled = userDefaults.bool(for: .soundEnabled)
      let audioVolume = userDefaults.float(for: .audioVolume) == 0.0 ? 0.5 : userDefaults.float(for: .audioVolume)
      let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
      let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
      let userLanguage = userDefaults.string(for: .userLanguage) ?? "en"

      return State(
        soundEnabled: soundEnabled,
        audioVolume: audioVolume,
        sessionDuration: sessionDuration,
        userLanguage: userLanguage
      )
    }
  }
  
  public enum Action: Equatable {
    case onAppear
    case loadSettings(soundEnabled: Bool, audioVolume: Float, sessionDuration: Int, userLanguage: String)
    case toggleSound
    case setAudioVolume(Float)
    case setSessionDuration(Int)
    case setUserLanguage(String)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          // Load current settings from UserDefaults
          let soundEnabled = userDefaults.bool(for: .soundEnabled)
          let rawAudioVolume = userDefaults.float(for: .audioVolume)
          // Use saved volume if it exists, otherwise use 0.0 (will be set to 0.5 when enabling sound)
          let audioVolume = rawAudioVolume
          let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
          let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
          let userLanguage = userDefaults.string(for: .userLanguage) ?? "en"
          
          Log.settings.debug(
            """
            Loaded settings — sound: \(soundEnabled, privacy: .public), \
            volume: \(audioVolume, privacy: .public), \
            duration: \(sessionDuration, privacy: .public) min, \
            language: \(userLanguage, privacy: .public)
            """
          )

          await send(.loadSettings(
            soundEnabled: soundEnabled,
            audioVolume: audioVolume,
            sessionDuration: sessionDuration,
            userLanguage: userLanguage
          ))
        }

      case let .loadSettings(soundEnabled, audioVolume, sessionDuration, userLanguage):
        state.soundEnabled = soundEnabled
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
