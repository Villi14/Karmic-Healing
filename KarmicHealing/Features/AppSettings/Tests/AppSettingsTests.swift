//
// Karmic Healing 2025
//

import Common
import ComposableArchitecture
import ConcurrencyExtras
import Foundation
import UIKit
import XCTest
@testable import AppSettings

@MainActor
final class AppSettingsTests: XCTestCase {
  func testOnAppearLoadsStoredSettings() async {
    let store = TestStore(initialState: AppSettings.State()) {
      AppSettings()
    } withDependencies: {
      $0.userDefaults.integerForKey = { _ in 10 }
      $0.userDefaults.boolForKey = { key in key == "sound_enabled" }
      $0.userDefaults.floatForKey = { _ in 0.4 }
      $0.userDefaults.stringForKey = { _ in "dark" }
    }

    await store.send(.onAppear) {
      $0.sessionDuration = 10
      $0.soundEnabled = true
      $0.vibrationEnabled = false
      $0.audioVolume = 0.4
      $0.userTheme = "dark"
    }
  }

  func testOnAppearFallsBackToDefaultsWhenNothingStored() async {
    let store = TestStore(
      initialState: {
        var state = AppSettings.State()
        state.sessionDuration = 15
        state.userTheme = "light"
        return state
      }()
    ) {
      AppSettings()
    } withDependencies: {
      $0.userDefaults.integerForKey = { _ in 0 }
      $0.userDefaults.boolForKey = { _ in false }
      $0.userDefaults.floatForKey = { _ in 0 }
      $0.userDefaults.stringForKey = { _ in "" }
    }

    await store.send(.onAppear) {
      // A stored duration of 0 means "never set", so the current value is kept.
      $0.sessionDuration = 15
      $0.soundEnabled = false
      $0.vibrationEnabled = false
      $0.audioVolume = 0
      $0.userTheme = "system"
    }
  }

  func testDidTapAboutPresentsAboutAlert() async {
    let store = TestStore(initialState: AppSettings.State()) {
      AppSettings()
    }

    await store.send(.didTapAbout) {
      $0.destination = .aboutAlert(.showAbout())
    }
  }

  func testDidTapPrivacyPolicyPresentsPrivacyPolicy() async {
    let store = TestStore(initialState: AppSettings.State()) {
      AppSettings()
    }

    await store.send(.didTapPrivacyPolicy) {
      $0.destination = .privacyPolicy(.init())
    }
  }

  func testDidTapThemeSettingsPassesCurrentTheme() async {
    let store = TestStore(
      initialState: {
        var state = AppSettings.State()
        state.userTheme = "dark"
        return state
      }()
    ) {
      AppSettings()
    }

    await store.send(.didTapThemeSettings) {
      $0.destination = .themeSettings(.init(userTheme: "dark"))
    }
  }

  func testDidTapSessionDurationPassesCurrentSettings() async {
    let store = TestStore(
      initialState: {
        var state = AppSettings.State()
        state.sessionDuration = 15
        state.soundEnabled = true
        state.vibrationEnabled = false
        state.audioVolume = 0.7
        return state
      }()
    ) {
      AppSettings()
    }

    await store.send(.didTapSessionDuration) {
      $0.destination = .sessionDurationAlert(
        .init(
          sessionDuration: 15,
          soundEnabled: true,
          vibrationEnabled: false,
          audioVolume: 0.7
        )
      )
    }
  }

  func testDidTapChangeLanguageOpensSystemSettings() async {
    let openedURLs = LockIsolated<[URL]>([])

    let store = TestStore(initialState: AppSettings.State()) {
      AppSettings()
    } withDependencies: {
      $0.openURL = OpenURLEffect { url in
        openedURLs.withValue { $0.append(url) }
        return true
      }
    }

    await store.send(.didTapChangeLanguage)
    await store.finish()

    XCTAssertEqual(openedURLs.value.map(\.absoluteString), [UIApplication.openSettingsURLString])
  }

  func testAboutAlertOpensAuthorSite() async {
    let openedURLs = LockIsolated<[URL]>([])

    let store = TestStore(
      initialState: {
        var state = AppSettings.State()
        state.destination = .aboutAlert(.showAbout())
        return state
      }()
    ) {
      AppSettings()
    } withDependencies: {
      $0.openURL = OpenURLEffect { url in
        openedURLs.withValue { $0.append(url) }
        return true
      }
    }

    await store.send(.destination(.presented(.aboutAlert(.openAuthorSite))))
    await store.finish()

    XCTAssertEqual(openedURLs.value.map(\.absoluteString), ["https://www.dianestein.net"])
  }

  func testDidTapContactEmailPresentsMailComposerOrClipboardAlert() async {
    let store = TestStore(initialState: AppSettings.State()) {
      AppSettings()
    }
    store.exhaustivity = .off

    await store.send(.didTapContactEmail)

    switch store.state.destination {
    case .mailComposer:
      XCTAssertTrue(MailComposerView.canShowMailComposer)
    case .clipboardAlert(let alert):
      XCTAssertFalse(MailComposerView.canShowMailComposer)
      XCTAssertEqual(alert, .contactUs)
    default:
      XCTFail("Unexpected destination: \(String(describing: store.state.destination))")
    }
  }

  func testSettingChangesArePersisted() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: AppSettings.State()) {
      AppSettings()
    } withDependencies: {
      $0.userDefaults.setInteger = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.userDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.userDefaults.setFloat = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.userDefaults.setString = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.sessionDurationChanged(3)) { $0.sessionDuration = 3 }
    await store.send(.soundEnabledChanged(false)) { $0.soundEnabled = false }
    await store.send(.vibrationEnabledChanged(false)) { $0.vibrationEnabled = false }
    await store.send(.audioVolumeChanged(0.9)) { $0.audioVolume = 0.9 }
    await store.send(.themeChanged("light")) { $0.userTheme = "light" }
    await store.finish()

    XCTAssertEqual(
      writes.value,
      [
        "session_duration=3",
        "sound_enabled=false",
        "vibration_enabled=false",
        "audio_volume=0.9",
        "user_theme=light"
      ]
    )
  }

  func testThemeChangeFromChildIsPersisted() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(
      initialState: {
        var state = AppSettings.State()
        state.destination = .themeSettings(.init(userTheme: "system"))
        return state
      }()
    ) {
      AppSettings()
    } withDependencies: {
      $0.userDefaults.setString = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.destination(.presented(.themeSettings(.themeChanged("dark"))))) {
      $0.destination = .themeSettings(.init(userTheme: "dark"))
    }
    await store.finish()

    XCTAssertEqual(writes.value, ["user_theme=dark"])
  }
}
