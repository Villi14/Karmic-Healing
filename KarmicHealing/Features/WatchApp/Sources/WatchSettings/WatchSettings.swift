//
// Karmic Healing 2025
//

import ComposableArchitecture
import Foundation

@Reducer
public struct WatchSettings {
  @Dependency(\.watchUserDefaults) var userDefaults
  
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    public var soundEnabled: Bool
    public var vibrationEnabled: Bool
    public var audioVolume: Float
    public var sessionDuration: Int
    public var userLanguage: String
    
    public init(
      soundEnabled: Bool = false,
      vibrationEnabled: Bool = false,
      audioVolume: Float = 0.5,
      sessionDuration: Int = 5,
      userLanguage: String = "en"
    ) {
      self.soundEnabled = soundEnabled
      self.vibrationEnabled = vibrationEnabled
      self.audioVolume = audioVolume
      self.sessionDuration = sessionDuration
      self.userLanguage = userLanguage
    }
    
    // Static method to create state with loaded settings
    public static func withLoadedSettings(userDefaults: WatchUserDefaultsClient) -> State {
      let soundEnabled = userDefaults.bool(for: .soundEnabled)
      let vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
      let audioVolume = userDefaults.float(for: .audioVolume) == 0.0 ? 0.5 : userDefaults.float(for: .audioVolume)
      let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
      let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
      let userLanguage = userDefaults.string(for: .userLanguage) ?? "en"
      
      return State(
        soundEnabled: soundEnabled,
        vibrationEnabled: vibrationEnabled,
        audioVolume: audioVolume,
        sessionDuration: sessionDuration,
        userLanguage: userLanguage
      )
    }
  }
  
  public enum Action: Equatable {
    case onAppear
    case loadSettings(soundEnabled: Bool, vibrationEnabled: Bool, audioVolume: Float, sessionDuration: Int, userLanguage: String)
    case toggleSound
    case toggleVibration
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
          let vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
          let rawAudioVolume = userDefaults.float(for: .audioVolume)
          // Use saved volume if it exists, otherwise use 0.0 (will be set to 0.5 when enabling sound)
          let audioVolume = rawAudioVolume
          let rawSessionDuration = userDefaults.integer(for: .sessionDuration)
          let sessionDuration = rawSessionDuration == 0 ? 5 : rawSessionDuration
          let userLanguage = userDefaults.string(for: .userLanguage) ?? "en"
          
          print("🔊 WatchSettings: Loading settings from UserDefaults:")
          print("  soundEnabled: \(soundEnabled)")
          print("  vibrationEnabled: \(vibrationEnabled)")
          print("  rawAudioVolume: \(rawAudioVolume)")
          print("  audioVolume (processed): \(audioVolume)")
          if rawAudioVolume > 0.0 {
            print("  ✅ Using saved volume: \(rawAudioVolume)")
          } else {
            print("  🔄 No saved volume, will use default when enabling sound")
          }
          print("  sessionDuration: \(sessionDuration)")
          print("  userLanguage: \(userLanguage)")
          
          await send(.loadSettings(
            soundEnabled: soundEnabled,
            vibrationEnabled: vibrationEnabled,
            audioVolume: audioVolume,
            sessionDuration: sessionDuration,
            userLanguage: userLanguage
          ))
        }
        
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
          if savedVolume > 0.0 {
            state.audioVolume = savedVolume
            print("🔊 WatchSettings: Enabling sound with restored volume \(savedVolume)")
          } else {
            state.audioVolume = 0.5
            print("🔊 WatchSettings: Enabling sound with default 50% volume")
          }
        } else {
          print("🔊 WatchSettings: Disabling sound (keeping volume \(state.audioVolume) for later)")
        }
        
        return .run { [state] send in
          await userDefaults.setAsync(state.soundEnabled, for: .soundEnabled)
          if state.soundEnabled {
            await userDefaults.setAsync(state.audioVolume, for: .audioVolume)
            print("🔊 WatchSettings: Saved sound enabled with volume \(state.audioVolume)")
          }
        }
        
      case .toggleVibration:
        state.vibrationEnabled.toggle()
        return .run { [state] send in
          await userDefaults.setAsync(state.vibrationEnabled, for: .vibrationEnabled)
        }
        
      case let .setAudioVolume(volume):
        state.audioVolume = volume
        print("🔊 WatchSettings: Setting audio volume to \(volume)")
        return .run { [state] send in
          await userDefaults.setAsync(state.audioVolume, for: .audioVolume)
          print("🔊 WatchSettings: Saved audio volume \(state.audioVolume) to UserDefaults")
          
          // Verify it was saved
          let savedVolume = userDefaults.float(for: .audioVolume)
          print("🔊 WatchSettings: Verified saved volume: \(savedVolume)")
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
