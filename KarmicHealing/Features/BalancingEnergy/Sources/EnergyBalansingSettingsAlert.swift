//
// Karmic Healing 2025
//

import ComposableArchitecture
import Dependencies

@Reducer
public struct EnergyBalansingSettingsAlert {
  @Dependency(\.userDefaults) var userDefaults
  
  @ObservableState
  public struct State: Equatable {
    public var sessionDuration: Int
    public var soundEnabled: Bool
    public var vibrationEnabled: Bool
    public var audioVolume: Float
    
    public init(
      sessionDuration: Int = 5,
      soundEnabled: Bool = true,
      vibrationEnabled: Bool = true,
      audioVolume: Float = 1.0
    ) {
      self.sessionDuration = sessionDuration
      self.soundEnabled = soundEnabled
      self.vibrationEnabled = vibrationEnabled
      self.audioVolume = audioVolume
    }
  }
  
  public enum Action: Equatable {
    case sessionDurationChanged(Int)
    case soundEnabledChanged(Bool)
    case vibrationEnabledChanged(Bool)
    case audioVolumeChanged(Float)
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
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(volume, for: .audioVolume)
        }
        
      case .done:
        return .none
        
      case .onAppear:
        state.sessionDuration = userDefaults.integer(for: .sessionDuration)
        state.soundEnabled = userDefaults.bool(for: .soundEnabled)
        state.vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
        state.audioVolume = userDefaults.float(for: .audioVolume)
        return .none
      }
    }
  }
} 