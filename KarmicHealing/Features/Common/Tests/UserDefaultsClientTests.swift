//
// Karmic Healing 2025
//

import ConcurrencyExtras
import XCTest
@testable import Common

final class UserDefaultsClientTests: XCTestCase {
  func testTypeSafeKeysUseExpectedRawValues() {
    XCTAssertEqual(BoolKey.showedOnboarding.rawValue, "showed_onboarding")
    XCTAssertEqual(BoolKey.soundEnabled.rawValue, "sound_enabled")
    XCTAssertEqual(BoolKey.vibrationEnabled.rawValue, "vibration_enabled")
    XCTAssertEqual(BoolKey.initialProcessCompleted.rawValue, "initial_process_completed")
    XCTAssertEqual(StringKey.userLanguage.rawValue, "user_language")
    XCTAssertEqual(StringKey.userTheme.rawValue, "user_theme")
    XCTAssertEqual(IntKey.lastCompletedStep.rawValue, "last_completed_step")
    XCTAssertEqual(IntKey.appLaunchCount.rawValue, "app_launch_count")
    XCTAssertEqual(IntKey.sessionDuration.rawValue, "session_duration")
    XCTAssertEqual(FloatKey.audioVolume.rawValue, "audio_volume")
  }

  func testGettersForwardKeyRawValue() {
    let requestedKeys = LockIsolated<[String]>([])
    let client = UserDefaultsClient.mock(
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
        return "dark"
      },
      objectForKey: { key in
        requestedKeys.withValue { $0.append(key) }
        return true
      }
    )

    XCTAssertTrue(client.bool(for: .soundEnabled))
    XCTAssertEqual(client.float(for: .audioVolume), 0.25)
    XCTAssertEqual(client.integer(for: .sessionDuration), 15)
    XCTAssertEqual(client.string(for: .userTheme), "dark")
    XCTAssertEqual(client.object(for: .vibrationEnabled) as? Bool, true)

    XCTAssertEqual(
      requestedKeys.value,
      [
        "sound_enabled",
        "audio_volume",
        "session_duration",
        "user_theme",
        "vibration_enabled"
      ]
    )
  }

  @MainActor
  func testAsyncSettersForwardValueAndKey() async {
    let writes = LockIsolated<[String]>([])
    let client = UserDefaultsClient.mock(
      setBool: { value, key in writes.withValue { $0.append("\(key)=\(value)") } },
      setFloat: { value, key in writes.withValue { $0.append("\(key)=\(value)") } },
      setInteger: { value, key in writes.withValue { $0.append("\(key)=\(value)") } },
      setString: { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    )

    await client.setAsync(true, for: .showedOnboarding)
    await client.setAsync(0.75 as Float, for: .audioVolume)
    await client.setAsync(10, for: .sessionDuration)
    await client.setAsync("light", for: .userTheme)

    XCTAssertEqual(
      writes.value,
      [
        "showed_onboarding=true",
        "audio_volume=0.75",
        "session_duration=10",
        "user_theme=light"
      ]
    )
  }

  func testTestValueReturnsNeutralDefaults() {
    let client = UserDefaultsClient.testValue

    XCTAssertFalse(client.bool(for: .soundEnabled))
    XCTAssertEqual(client.integer(for: .sessionDuration), 0)
    XCTAssertEqual(client.float(for: .audioVolume), 1.0)
    XCTAssertNil(client.string(for: .userTheme))
    XCTAssertNil(client.object(for: .soundEnabled))
  }
}

extension UserDefaultsClient {
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
