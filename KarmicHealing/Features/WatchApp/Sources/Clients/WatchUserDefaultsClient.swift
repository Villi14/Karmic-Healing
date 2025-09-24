//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import XCTestDynamicOverlay
import WatchConnectivity

extension DependencyValues {
  public var watchUserDefaults: WatchUserDefaultsClient {
    get { self[WatchUserDefaultsClient.self] }
    set { self[WatchUserDefaultsClient.self] = newValue }
  }
}

public struct WatchUserDefaultsClient {
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

extension WatchUserDefaultsClient: DependencyKey {
  public static let liveValue: Self = {
    return Self(
      boolForKey: { UserDefaults.standard.bool(forKey: $0) },
      dataForKey: { UserDefaults.standard.data(forKey: $0) },
      doubleForKey: { UserDefaults.standard.double(forKey: $0) },
      floatForKey: { UserDefaults.standard.float(forKey: $0) },
      integerForKey: { UserDefaults.standard.integer(forKey: $0) },
      stringForKey: { UserDefaults.standard.string(forKey: $0) },
      objectForKey: { UserDefaults.standard.object(forKey: $0) },
      remove: { UserDefaults.standard.removeObject(forKey: $0) },
      setBool: { value, key in
        UserDefaults.standard.set(value, forKey: key)
      },
      setData: { value, key in
        UserDefaults.standard.set(value, forKey: key)
      },
      setDouble: { value, key in
        UserDefaults.standard.set(value, forKey: key)
      },
      setFloat: { value, key in
        UserDefaults.standard.set(value, forKey: key)
      },
      setInteger: { value, key in
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
      },
      setString: { value, key in
        UserDefaults.standard.set(value, forKey: key)
      }
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
extension WatchUserDefaultsClient {
  public enum Keys {
    public static let userLanguage = "user_language"
    public static let lastCompletedStep = "last_completed_step"
    public static let sessionDuration = "session_duration"
    public static let soundEnabled = "sound_enabled"
    public static let vibrationEnabled = "vibration_enabled"
    public static let audioVolume = "audio_volume"
    public static let userTheme = "user_theme"
    public static let activeMeditationTitle = "active_meditation_title"
    public static let activeMeditationStep = "active_meditation_step"
    public static let activeMeditationCompleted = "active_meditation_completed"
    public static let hasActiveMeditation = "has_active_meditation"
    public static let activeMeditationType = "active_meditation_type"
  }
}

// MARK: - Type-safe keys (non-generic approach)
public struct BoolKey {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public static let soundEnabled = BoolKey(WatchUserDefaultsClient.Keys.soundEnabled)
  public static let vibrationEnabled = BoolKey(WatchUserDefaultsClient.Keys.vibrationEnabled)
  public static let activeMeditationCompleted = BoolKey(WatchUserDefaultsClient.Keys.activeMeditationCompleted)
  public static let hasActiveMeditation = BoolKey(WatchUserDefaultsClient.Keys.hasActiveMeditation)
}

public struct StringKey {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public static let userLanguage = StringKey(WatchUserDefaultsClient.Keys.userLanguage)
  public static let userTheme = StringKey(WatchUserDefaultsClient.Keys.userTheme)
  public static let activeMeditationTitle = StringKey(WatchUserDefaultsClient.Keys.activeMeditationTitle)
  public static let activeMeditationType = StringKey(WatchUserDefaultsClient.Keys.activeMeditationType)
}

public struct IntKey {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public static let lastCompletedStep = IntKey(WatchUserDefaultsClient.Keys.lastCompletedStep)
  public static let sessionDuration = IntKey(WatchUserDefaultsClient.Keys.sessionDuration)
  public static let activeMeditationStep = IntKey(WatchUserDefaultsClient.Keys.activeMeditationStep)
}

public struct FloatKey {
  public let rawValue: String

  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }

  public static let audioVolume = FloatKey(WatchUserDefaultsClient.Keys.audioVolume)
}

// MARK: - Convenience methods
extension WatchUserDefaultsClient {
  // MARK: - Type-safe getters
  public func bool(for key: BoolKey) -> Bool {
    boolForKey(key.rawValue)
  }

  public func string(for key: StringKey) -> String? {
    stringForKey(key.rawValue)
  }

  public func integer(for key: IntKey) -> Int {
    return integerForKey(key.rawValue)
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
}
