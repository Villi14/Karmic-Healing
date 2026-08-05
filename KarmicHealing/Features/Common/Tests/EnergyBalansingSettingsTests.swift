//
// Karmic Healing 2025
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import Common

@MainActor
final class EnergyBalansingSettingsTests: XCTestCase {
  func testOnAppearWritesDefaultsOnFirstLaunch() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(
      initialState: EnergyBalansingSettings.State(
        sessionDuration: 15,
        soundEnabled: true,
        vibrationEnabled: true,
        audioVolume: 1.0
      )
    ) {
      EnergyBalansingSettings()
    } withDependencies: {
      // No stored `soundEnabled` object means the user never opened settings before.
      $0.userDefaults.objectForKey = { _ in nil }
      $0.userDefaults.integerForKey = { _ in 0 }
      $0.userDefaults.setInteger = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.userDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.userDefaults.setFloat = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.onAppear) {
      $0.sessionDuration = 5
      $0.soundEnabled = false
      $0.vibrationEnabled = false
      $0.audioVolume = 0.5
    }
    await store.finish()

    XCTAssertEqual(
      writes.value,
      [
        "session_duration=5",
        "sound_enabled=false",
        "vibration_enabled=false",
        "audio_volume=0.5"
      ]
    )
  }

  func testOnAppearLoadsStoredSettingsAndAppliesVolume() async {
    let appliedVolume = LockIsolated<[Float]>([])

    let store = TestStore(initialState: EnergyBalansingSettings.State()) {
      EnergyBalansingSettings()
    } withDependencies: {
      $0.userDefaults.objectForKey = { _ in true }
      $0.userDefaults.integerForKey = { _ in 10 }
      $0.userDefaults.boolForKey = { _ in true }
      $0.userDefaults.floatForKey = { _ in 0.3 }
      $0.audio.setVolume = { volume in appliedVolume.withValue { $0.append(volume) } }
    }

    await store.send(.onAppear) {
      $0.sessionDuration = 10
      $0.soundEnabled = true
      $0.vibrationEnabled = true
      $0.audioVolume = 0.3
      // The same stubs back the screen-rest keys, so they read stored values too.
      $0.screenRestEnabled = true
      $0.screenRestDelay = 10
    }
    await store.finish()

    XCTAssertEqual(appliedVolume.value, [0.3])
  }

  func testScreenRestSettingsPersist() async {
    let boolWrites = LockIsolated<[String]>([])
    let intWrites = LockIsolated<[String]>([])

    let store = TestStore(initialState: EnergyBalansingSettings.State()) {
      EnergyBalansingSettings()
    } withDependencies: {
      $0.userDefaults.setBool = { value, key in boolWrites.withValue { $0.append("\(key)=\(value)") } }
      $0.userDefaults.setInteger = { value, key in intWrites.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.screenRestEnabledChanged(false)) { $0.screenRestEnabled = false }
    await store.send(.screenRestDelayChanged(120)) { $0.screenRestDelay = 120 }
    await store.finish()

    XCTAssertEqual(boolWrites.value, ["screen_rest_enabled=false"])
    XCTAssertEqual(intWrites.value, ["screen_rest_delay=120"])
  }

  func testScreenRestIsOnUntilTheUserTurnsItOff() async {
    // `bool(forKey:)` alone cannot tell "off" from "never set", so an untouched install must
    // still get the darkening behaviour.
    let store = TestStore(initialState: EnergyBalansingSettings.State()) {
      EnergyBalansingSettings()
    } withDependencies: {
      $0.userDefaults.objectForKey = { key in key == "sound_enabled" ? true : nil }
      $0.userDefaults.boolForKey = { _ in false }
      $0.userDefaults.integerForKey = { _ in 0 }
      $0.userDefaults.floatForKey = { _ in 0.5 }
    }

    await store.send(.onAppear)
    XCTAssertTrue(store.state.screenRestEnabled)
    XCTAssertEqual(store.state.screenRestDelay, EnergyBalansingSettings.defaultRestDelay)
    await store.finish()
  }

  func testSessionDurationChangedPersistsValue() async {
    let writes = LockIsolated<[Int]>([])

    let store = TestStore(initialState: EnergyBalansingSettings.State()) {
      EnergyBalansingSettings()
    } withDependencies: {
      $0.userDefaults.setInteger = { value, _ in writes.withValue { $0.append(value) } }
    }

    await store.send(.sessionDurationChanged(15)) {
      $0.sessionDuration = 15
    }
    await store.finish()

    XCTAssertEqual(writes.value, [15])
  }

  func testTogglesPersistTheirValues() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: EnergyBalansingSettings.State()) {
      EnergyBalansingSettings()
    } withDependencies: {
      $0.userDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.soundEnabledChanged(true)) {
      $0.soundEnabled = true
    }
    await store.send(.vibrationEnabledChanged(true)) {
      $0.vibrationEnabled = true
    }
    await store.finish()

    XCTAssertEqual(writes.value, ["sound_enabled=true", "vibration_enabled=true"])
  }

  func testAudioVolumeChangedPersistsAndAppliesVolume() async {
    let writes = LockIsolated<[Float]>([])
    let appliedVolume = LockIsolated<[Float]>([])

    let store = TestStore(initialState: EnergyBalansingSettings.State()) {
      EnergyBalansingSettings()
    } withDependencies: {
      $0.userDefaults.setFloat = { value, _ in writes.withValue { $0.append(value) } }
      $0.audio.setVolume = { volume in appliedVolume.withValue { $0.append(volume) } }
    }

    await store.send(.audioVolumeChanged(0.8)) {
      $0.audioVolume = 0.8
    }
    await store.finish()

    XCTAssertEqual(writes.value, [0.8])
    XCTAssertEqual(appliedVolume.value, [0.8])
  }

  func testDoneDismissesTheScreen() async {
    let didDismiss = LockIsolated(false)

    let store = TestStore(initialState: EnergyBalansingSettings.State()) {
      EnergyBalansingSettings()
    } withDependencies: {
      $0.dismiss = DismissEffect { didDismiss.setValue(true) }
    }

    await store.send(.done)
    await store.finish()

    XCTAssertTrue(didDismiss.value)
  }
}
