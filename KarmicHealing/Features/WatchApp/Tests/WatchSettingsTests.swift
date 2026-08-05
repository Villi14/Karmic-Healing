//
// Karmic Healing 2025
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import KarmicHealingWatch

@MainActor
final class WatchSettingsTests: XCTestCase {
  func testWithLoadedSettingsAppliesDefaultsForMissingValues() {
    var client = WatchUserDefaultsClient.testValue
    client.boolForKey = { _ in false }
    client.floatForKey = { _ in 0 }
    client.integerForKey = { _ in 0 }
    client.stringForKey = { _ in nil }

    let state = WatchSettings.State.withLoadedSettings(userDefaults: client)

    XCTAssertFalse(state.soundEnabled)
    XCTAssertFalse(state.vibrationEnabled)
    XCTAssertEqual(state.audioVolume, 0.5)
    XCTAssertEqual(state.sessionDuration, 5)
    XCTAssertEqual(state.userLanguage, "en")
  }

  func testWithLoadedSettingsUsesStoredValues() {
    var client = WatchUserDefaultsClient.testValue
    client.boolForKey = { _ in true }
    client.floatForKey = { _ in 0.3 }
    client.integerForKey = { _ in 10 }
    client.stringForKey = { _ in "uk" }

    let state = WatchSettings.State.withLoadedSettings(userDefaults: client)

    XCTAssertTrue(state.soundEnabled)
    XCTAssertTrue(state.vibrationEnabled)
    XCTAssertEqual(state.audioVolume, 0.3)
    XCTAssertEqual(state.sessionDuration, 10)
    XCTAssertEqual(state.userLanguage, "uk")
    XCTAssertTrue(state.screenRestEnabled)
    XCTAssertEqual(state.screenRestDelay, 10)
  }

  func testOnAppearLoadsSettings() async {
    let store = TestStore(initialState: WatchSettings.State()) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.boolForKey = { key in key == "sound_enabled" }
      $0.watchUserDefaults.floatForKey = { _ in 0.8 }
      $0.watchUserDefaults.integerForKey = { _ in 0 }
      $0.watchUserDefaults.stringForKey = { _ in "uk" }
    }

    await store.send(.onAppear)
    await store.receive(
      .loadSettings(
        soundEnabled: true,
        vibrationEnabled: false,
        audioVolume: 0.8,
        sessionDuration: 5,
        userLanguage: "uk"
      )
    ) {
      $0.soundEnabled = true
      $0.audioVolume = 0.8
      $0.sessionDuration = 5
      $0.userLanguage = "uk"
    }
    // Neither key was ever written, so both fall back to the defaults already in state.
    await store.receive(.loadScreenRest(enabled: true, delay: WatchBalancingEnergy.defaultRestDelay))
  }

  func testOnAppearLoadsStoredScreenRestPreferences() async {
    let store = TestStore(initialState: WatchSettings.State()) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.boolForKey = { _ in
        false
      }
      $0.watchUserDefaults.objectForKey = { key in
        key == WatchUserDefaultsClient.Keys.screenRestEnabled ? false : nil
      }
      $0.watchUserDefaults.integerForKey = { key in
        key == WatchUserDefaultsClient.Keys.screenRestDelay ? 60 : 0
      }
    }

    await store.send(.onAppear)
    await store.receive(
      .loadSettings(
        soundEnabled: false,
        vibrationEnabled: false,
        audioVolume: 1,
        sessionDuration: 5,
        userLanguage: "en"
      )
    ) {
      $0.audioVolume = 1
    }
    await store.receive(.loadScreenRest(enabled: false, delay: 60)) {
      $0.screenRestEnabled = false
      $0.screenRestDelay = 60
    }
  }

  func testToggleSoundRestoresSavedVolumeAndPersistsIt() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: WatchSettings.State()) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.floatForKey = { _ in 0.3 }
      $0.watchUserDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.watchUserDefaults.setFloat = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.toggleSound) {
      $0.soundEnabled = true
      $0.audioVolume = 0.3
    }
    await store.finish()

    XCTAssertEqual(writes.value, ["sound_enabled=true", "audio_volume=0.3"])
  }

  func testToggleSoundFallsBackToHalfVolume() async {
    let store = TestStore(initialState: WatchSettings.State(audioVolume: 0)) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.floatForKey = { _ in 0 }
    }

    await store.send(.toggleSound) {
      $0.soundEnabled = true
      $0.audioVolume = 0.5
    }
    await store.finish()
  }

  func testTogglingSoundOffKeepsTheVolume() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: WatchSettings.State(soundEnabled: true, audioVolume: 0.7)) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.toggleSound) {
      $0.soundEnabled = false
    }
    await store.finish()

    XCTAssertEqual(store.state.audioVolume, 0.7)
    XCTAssertEqual(writes.value, ["sound_enabled=false"])
  }

  func testToggleVibrationIsPersisted() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: WatchSettings.State()) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.toggleVibration) { $0.vibrationEnabled = true }
    await store.finish()

    XCTAssertEqual(writes.value, ["vibration_enabled=true"])
  }

  func testSetAudioVolumeAndSessionDurationArePersisted() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: WatchSettings.State()) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.setFloat = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.watchUserDefaults.setInteger = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.watchUserDefaults.floatForKey = { _ in 0.6 }
    }

    await store.send(.setAudioVolume(0.6)) { $0.audioVolume = 0.6 }
    await store.send(.setSessionDuration(15)) { $0.sessionDuration = 15 }
    await store.finish()

    XCTAssertEqual(writes.value, ["audio_volume=0.6", "session_duration=15"])
  }

  func testScreenRestPreferencesArePersisted() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: WatchSettings.State()) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.watchUserDefaults.setInteger = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.toggleScreenRest(false)) {
      $0.screenRestEnabled = false
    }
    await store.send(.setScreenRestDelay(120)) {
      $0.screenRestDelay = 120
    }
    await store.finish()

    XCTAssertEqual(writes.value, ["screen_rest_enabled=false", "screen_rest_delay=120"])
  }

  func testSetUserLanguageIsPersisted() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: WatchSettings.State()) {
      WatchSettings()
    } withDependencies: {
      $0.watchUserDefaults.setString = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.setUserLanguage("uk")) { $0.userLanguage = "uk" }
    await store.finish()

    XCTAssertEqual(writes.value, ["user_language=uk"])
  }
}
