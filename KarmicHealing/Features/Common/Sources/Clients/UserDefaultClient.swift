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
      boolForKey: { UserDefaults.standard.bool(forKey: $0) },
      dataForKey: { UserDefaults.standard.data(forKey: $0) },
      doubleForKey: { UserDefaults.standard.double(forKey: $0) },
      floatForKey: { UserDefaults.standard.float(forKey: $0) },
      integerForKey: { UserDefaults.standard.integer(forKey: $0) },
      stringForKey: { UserDefaults.standard.string(forKey: $0) },
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
}

public struct StringKey {
  public let rawValue: String
  
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  public static let userLanguage = StringKey(UserDefaultsClient.Keys.userLanguage)
  public static let userTheme = StringKey(UserDefaultsClient.Keys.userTheme)
}

public struct IntKey {
  public let rawValue: String
  
  public init(_ rawValue: String) {
    self.rawValue = rawValue
  }
  
  public static let lastCompletedStep = IntKey(UserDefaultsClient.Keys.lastCompletedStep)
  public static let appLaunchCount = IntKey(UserDefaultsClient.Keys.appLaunchCount)
  public static let sessionDuration = IntKey(UserDefaultsClient.Keys.sessionDuration)
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
  // Type-safe methods
  public func bool(for key: BoolKey) -> Bool {
    boolForKey(key.rawValue)
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
  
  @MainActor
  public func set(_ value: Bool, for key: BoolKey) {
    setBool(value, key.rawValue)
  }
  
  @MainActor
  public func set(_ value: String, for key: StringKey) {
    setString(value, key.rawValue)
  }
  
  @MainActor
  public func set(_ value: Int, for key: IntKey) {
    setInteger(value, key.rawValue)
  }
  
  @MainActor
  public func set(_ value: Float, for key: FloatKey) {
    setFloat(value, key.rawValue)
  }
  
  @MainActor
  public func remove(_ key: String) {
    remove(key)
  }
  
  // Async versions for non-MainActor contexts
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
  
  public func removeAsync(_ key: String) async {
    await MainActor.run {
      remove(key)
    }
  }
  
  // Simple string key methods
  public func bool(for key: String) -> Bool {
    boolForKey(key)
  }
  
  public func string(for key: String) -> String? {
    stringForKey(key)
  }
  
  public func integer(for key: String) -> Int {
    integerForKey(key)
  }
  
  @MainActor
  public func set(_ value: Bool, for key: String) {
    setBool(value, key)
  }
  
  @MainActor
  public func set(_ value: String, for key: String) {
    setString(value, key)
  }
  
  @MainActor
  public func set(_ value: Int, for key: String) {
    setInteger(value, key)
  }
  
  // Async versions for simple keys
  public func setAsync(_ value: Bool, for key: String) async {
    await MainActor.run {
      setBool(value, key)
    }
  }
  
  public func setAsync(_ value: String, for key: String) async {
    await MainActor.run {
      setString(value, key)
    }
  }
  
  public func setAsync(_ value: Int, for key: String) async {
    await MainActor.run {
      setInteger(value, key)
    }
  }
}

