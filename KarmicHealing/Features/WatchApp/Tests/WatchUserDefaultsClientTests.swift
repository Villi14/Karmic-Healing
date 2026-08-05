//
// Karmic Healing 2025
//

import ConcurrencyExtras
import XCTest
@testable import KarmicHealingWatch

final class WatchUserDefaultsClientTests: XCTestCase {
  /// The watch reads and writes the same keys the phone does, so a rename on one side has to be
  /// a rename on both.
  func testTypeSafeKeysUseExpectedRawValues() {
    XCTAssertEqual(BoolKey.soundEnabled.rawValue, "sound_enabled")
    XCTAssertEqual(BoolKey.vibrationEnabled.rawValue, "vibration_enabled")
    XCTAssertEqual(BoolKey.hasActiveMeditation.rawValue, "has_active_meditation")
    XCTAssertEqual(BoolKey.activeMeditationCompleted.rawValue, "active_meditation_completed")
    XCTAssertEqual(BoolKey.screenRestEnabled.rawValue, "screen_rest_enabled")
    XCTAssertEqual(StringKey.userLanguage.rawValue, "user_language")
    XCTAssertEqual(StringKey.userTheme.rawValue, "user_theme")
    XCTAssertEqual(StringKey.activeMeditationTitle.rawValue, "active_meditation_title")
    XCTAssertEqual(IntKey.lastCompletedStep.rawValue, "last_completed_step")
    XCTAssertEqual(IntKey.sessionDuration.rawValue, "session_duration")
    XCTAssertEqual(IntKey.activeMeditationStep.rawValue, "active_meditation_step")
    XCTAssertEqual(IntKey.screenRestDelay.rawValue, "screen_rest_delay")
    XCTAssertEqual(FloatKey.audioVolume.rawValue, "audio_volume")
  }

  func testGettersForwardKeyRawValue() {
    let requestedKeys = LockIsolated<[String]>([])
    let client = WatchUserDefaultsClient.mock(
      boolForKey: { key in
        requestedKeys.withValue { $0.append(key) }
        return true
      },
      floatForKey: { key in
        requestedKeys.withValue { $0.append(key) }
        return 0.25
      },
      integerForKey: { key in
        requestedKeys.withValue { $0.append(key) }
        return 15
      },
      stringForKey: { key in
        requestedKeys.withValue { $0.append(key) }
        return "uk"
      },
      objectForKey: { key in
        requestedKeys.withValue { $0.append(key) }
        return true
      }
    )

    XCTAssertTrue(client.bool(for: .soundEnabled))
    XCTAssertEqual(client.float(for: .audioVolume), 0.25)
    XCTAssertEqual(client.integer(for: .sessionDuration), 15)
    XCTAssertEqual(client.string(for: .userLanguage), "uk")
    XCTAssertEqual(client.object(for: .vibrationEnabled) as? Bool, true)

    XCTAssertEqual(
      requestedKeys.value,
      [
        "sound_enabled",
        "audio_volume",
        "session_duration",
        "user_language",
        "vibration_enabled"
      ]
    )
  }

  /// Screen rest is on until the user turns it off, so "never touched" has to read as on while
  /// a stored `false` reads as off — `bool(forKey:)` alone answers `false` to both.
  func testAFlagThatWasNeverSetFallsBackToItsDefault() {
    let untouched = WatchUserDefaultsClient.mock(
      boolForKey: { _ in false },
      objectForKey: { _ in nil }
    )
    XCTAssertTrue(untouched.bool(for: .screenRestEnabled, default: true))
    XCTAssertFalse(untouched.bool(for: .screenRestEnabled, default: false))

    let turnedOff = WatchUserDefaultsClient.mock(
      boolForKey: { _ in false },
      objectForKey: { _ in false }
    )
    XCTAssertFalse(turnedOff.bool(for: .screenRestEnabled, default: true))
  }

  @MainActor
  func testAsyncSettersForwardValueAndKey() async {
    let writes = LockIsolated<[String]>([])
    let client = WatchUserDefaultsClient.mock(
      setBool: { value, key in writes.withValue { $0.append("\(key)=\(value)") } },
      setFloat: { value, key in writes.withValue { $0.append("\(key)=\(value)") } },
      setInteger: { value, key in writes.withValue { $0.append("\(key)=\(value)") } },
      setString: { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    )

    await client.setAsync(true, for: .soundEnabled)
    await client.setAsync(0.75 as Float, for: .audioVolume)
    await client.setAsync(10, for: .sessionDuration)
    await client.setAsync("uk", for: .userLanguage)

    XCTAssertEqual(
      writes.value,
      [
        "sound_enabled=true",
        "audio_volume=0.75",
        "session_duration=10",
        "user_language=uk"
      ]
    )
  }

  func testTestValueReturnsNeutralDefaults() {
    let client = WatchUserDefaultsClient.testValue

    XCTAssertFalse(client.bool(for: .soundEnabled))
    XCTAssertEqual(client.integer(for: .sessionDuration), 0)
    XCTAssertEqual(client.float(for: .audioVolume), 1.0)
    XCTAssertNil(client.string(for: .userLanguage))
    XCTAssertNil(client.object(for: .soundEnabled))
  }
}

extension WatchUserDefaultsClient {
  /// `testValue` with only the endpoints a test cares about overridden.
  fileprivate static func mock(
    boolForKey: @escaping @Sendable (String) -> Bool = { _ in false },
    floatForKey: @escaping @Sendable (String) -> Float = { _ in 0 },
    integerForKey: @escaping @Sendable (String) -> Int = { _ in 0 },
    stringForKey: @escaping @Sendable (String) -> String? = { _ in nil },
    objectForKey: @escaping @Sendable (String) -> Any? = { _ in nil },
    setBool: @escaping @MainActor @Sendable (Bool, String) -> Void = { _, _ in },
    setFloat: @escaping @MainActor @Sendable (Float, String) -> Void = { _, _ in },
    setInteger: @escaping @MainActor @Sendable (Int, String) -> Void = { _, _ in },
    setString: @escaping @MainActor @Sendable (String, String) -> Void = { _, _ in }
  ) -> Self {
    var client = Self.testValue
    client.boolForKey = boolForKey
    client.floatForKey = floatForKey
    client.integerForKey = integerForKey
    client.stringForKey = stringForKey
    client.objectForKey = objectForKey
    client.setBool = setBool
    client.setFloat = setFloat
    client.setInteger = setInteger
    client.setString = setString
    return client
  }
}
