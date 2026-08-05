//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import XCTestDynamicOverlay

extension DependencyValues {
  public var userDefaults: UserDefaultsClient {
    get { self[UserDefaultsClient.self] }
    set { self[UserDefaultsClient.self] = newValue }
  }
}

public struct UserDefaultsClient {
  public var boolForKey: @Sendable (String) -> Bool
  public var dataForKey: @Sendable (String) -> Data?
  public var doubleForKey: @Sendable (String) -> Double
  public var floatForKey: @Sendable (String) -> Float
  public var integerForKey: @Sendable (String) -> Int
  public var stringForKey: @Sendable (String) -> String?
  public var objectForKey: @Sendable (String) -> Any?
  public var remove: @MainActor @Sendable (String) -> Void
  public var setBool: @MainActor @Sendable (Bool, String) -> Void
  public var setData: @MainActor @Sendable (Data?, String) -> Void
  public var setDouble: @MainActor @Sendable (Double, String) -> Void
  public var setFloat: @MainActor @Sendable (Float, String) -> Void
  public var setInteger: @MainActor @Sendable (Int, String) -> Void
  public var setString: @MainActor @Sendable (String, String) -> Void

  public init(
    boolForKey: @Sendable @escaping (String) -> Bool,
    dataForKey: @Sendable @escaping (String) -> Data?,
    doubleForKey: @Sendable @escaping (String) -> Double,
    floatForKey: @Sendable @escaping (String) -> Float,
    integerForKey: @Sendable @escaping (String) -> Int,
    stringForKey: @Sendable @escaping (String) -> String?,
    objectForKey: @Sendable @escaping (String) -> Any?,
    remove: @MainActor @Sendable @escaping (String) -> Void,
    setBool: @MainActor @Sendable @escaping (Bool, String) -> Void,
    setData: @MainActor @Sendable @escaping (Data?, String) -> Void,
    setDouble: @MainActor @Sendable @escaping (Double, String) -> Void,
    setFloat: @MainActor @Sendable @escaping (Float, String) -> Void,
    setInteger: @MainActor @Sendable @escaping (Int, String) -> Void,
    setString: @MainActor @Sendable @escaping (String, String) -> Void
  ) {
    self.boolForKey = boolForKey
    self.dataForKey = dataForKey
    self.doubleForKey = doubleForKey
    self.floatForKey = floatForKey
    self.integerForKey = integerForKey
    self.stringForKey = stringForKey
    self.objectForKey = objectForKey
    self.remove = remove
    self.setBool = setBool
    self.setData = setData
    self.setDouble = setDouble
    self.setFloat = setFloat
    self.setInteger = setInteger
    self.setString = setString
  }
}

extension UserDefaultsClient: DependencyKey {
  public static let liveValue: Self = {
    return Self(
      boolForKey: { key in
        // Set default values for sound and vibration to false
        if key == UserDefaultsClient.Keys.soundEnabled || key == UserDefaultsClient.Keys.vibrationEnabled {
          let value = UserDefaults.standard.object(forKey: key)
          if value == nil {
            // First time - return false as default
            return false
          }
        }
        return UserDefaults.standard.bool(forKey: key)
      },
      dataForKey: { UserDefaults.standard.data(forKey: $0) },
      doubleForKey: { UserDefaults.standard.double(forKey: $0) },
      floatForKey: { UserDefaults.standard.float(forKey: $0) },
      integerForKey: { UserDefaults.standard.integer(forKey: $0) },
      stringForKey: { UserDefaults.standard.string(forKey: $0) },
      objectForKey: { UserDefaults.standard.object(forKey: $0) },
      remove: { UserDefaults.standard.removeObject(forKey: $0) },
      setBool: { UserDefaults.standard.set($0, forKey: $1) },
      setData: { UserDefaults.standard.set($0, forKey: $1) },
      setDouble: { UserDefaults.standard.set($0, forKey: $1) },
      setFloat: { UserDefaults.standard.set($0, forKey: $1) },
      setInteger: { UserDefaults.standard.set($0, forKey: $1) },
      setString: { UserDefaults.standard.set($0, forKey: $1) }
    )
  }()
  
  public static let testValue: Self = {
    return Self(
      boolForKey: { _ in false },
      dataForKey: { _ in nil },
      doubleForKey: { _ in 0.0 },
      floatForKey: { _ in 1.0 },
      integerForKey: { _ in 0 },
      stringForKey: { _ in nil },
      objectForKey: { _ in nil },
      remove: { _ in },
      setBool: { _, _ in },
      setData: { _, _ in },
      setDouble: { _, _ in },
      setFloat: { _, _ in },
      setInteger: { _, _ in },
      setString: { _, _ in }
    )
  }()
}

// MARK: - Keys
extension UserDefaultsClient {
  public enum Keys {
    public static let showedOnboarding = "showed_onboarding"
    public static let userLanguage = "user_language"
    public static let lastCompletedStep = "last_completed_step"
    public static let appLaunchCount = "app_launch_count"
    public static let sessionDuration = "session_duration"
    public static let soundEnabled = "sound_enabled"
    public static let vibrationEnabled = "vibration_enabled"
    public static let audioVolume = "audio_volume"
    public static let userTheme = "user_theme"
    public static let initialProcessCompleted = "initial_process_completed"
    public static let activeSessionKind = "active_session_kind"
    public static let activeSessionStep = "active_session_step"
    public static let screenRestEnabled = "screen_rest_enabled"
    public static let screenRestDelay = "screen_rest_delay"
    public static let brightnessBeforeSession = "brightness_before_session"
  }
}

// MARK: - Type-safe keys (non-generic approach)
public struct BoolKey {
  public let rawValue: String
  
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  public static let showedOnboarding = BoolKey(UserDefaultsClient.Keys.showedOnboarding)
  public static let soundEnabled = BoolKey(UserDefaultsClient.Keys.soundEnabled)
  public static let vibrationEnabled = BoolKey(UserDefaultsClient.Keys.vibrationEnabled)
  public static let initialProcessCompleted = BoolKey(UserDefaultsClient.Keys.initialProcessCompleted)
  /// Darkening the screen between steps. On unless the user turns it off.
  public static let screenRestEnabled = BoolKey(UserDefaultsClient.Keys.screenRestEnabled)
}

public struct StringKey {
  public let rawValue: String
  
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  public static let userLanguage = StringKey(UserDefaultsClient.Keys.userLanguage)
  public static let userTheme = StringKey(UserDefaultsClient.Keys.userTheme)
  /// The meditation a session was left in, so a notification tap can reopen it.
  public static let activeSessionKind = StringKey(UserDefaultsClient.Keys.activeSessionKind)
}

public struct IntKey {
  public let rawValue: String
  
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  public static let lastCompletedStep = IntKey(UserDefaultsClient.Keys.lastCompletedStep)
  public static let appLaunchCount = IntKey(UserDefaultsClient.Keys.appLaunchCount)
  public static let sessionDuration = IntKey(UserDefaultsClient.Keys.sessionDuration)
  public static let activeSessionStep = IntKey(UserDefaultsClient.Keys.activeSessionStep)
  /// Seconds of stillness before the screen rests.
  public static let screenRestDelay = IntKey(UserDefaultsClient.Keys.screenRestDelay)
}

public struct FloatKey {
  public let rawValue: String
  
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  public static let audioVolume = FloatKey(UserDefaultsClient.Keys.audioVolume)
}

// MARK: - Convenience methods
extension UserDefaultsClient {
  // MARK: - Type-safe getters
  public func bool(for key: BoolKey) -> Bool {
    boolForKey(key.rawValue)
  }

  /// A stored flag, or `fallback` when the user has never set it — `bool(forKey:)` alone cannot
  /// tell "off" from "never touched", which matters for settings that default to on.
  public func bool(for key: BoolKey, default fallback: Bool) -> Bool {
    objectForKey(key.rawValue) == nil ? fallback : boolForKey(key.rawValue)
  }
  
  public func string(for key: StringKey) -> String? {
    stringForKey(key.rawValue)
  }
  
  public func integer(for key: IntKey) -> Int {
    integerForKey(key.rawValue)
  }
  
  public func float(for key: FloatKey) -> Float {
    floatForKey(key.rawValue)
  }
  
  public func object(for key: BoolKey) -> Any? {
    objectForKey(key.rawValue)
  }

  // MARK: - Type-safe async setters
  public func setAsync(_ value: Bool, for key: BoolKey) async {
    await MainActor.run {
      setBool(value, key.rawValue)
    }
  }
  
  public func setAsync(_ value: String, for key: StringKey) async {
    await MainActor.run {
      setString(value, key.rawValue)
    }
  }
  
  public func setAsync(_ value: Int, for key: IntKey) async {
    await MainActor.run {
      setInteger(value, key.rawValue)
    }
  }
  
  public func setAsync(_ value: Float, for key: FloatKey) async {
    await MainActor.run {
      setFloat(value, key.rawValue)
    }
  }

  // MARK: - Type-safe removal
  public func removeAsync(_ key: StringKey) async {
    await MainActor.run {
      remove(key.rawValue)
    }
  }

  public func removeAsync(_ key: IntKey) async {
    await MainActor.run {
      remove(key.rawValue)
    }
  }
}

