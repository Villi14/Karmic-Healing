//
// Karmic Healing 2025
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import AppSettings

@MainActor
final class ThemeSettingsTests: XCTestCase {
  func testOnAppearLoadsStoredTheme() async {
    let store = TestStore(initialState: ThemeSettings.State()) {
      ThemeSettings()
    } withDependencies: {
      $0.userDefaults.stringForKey = { _ in "dark" }
    }

    await store.send(.onAppear) {
      $0.userTheme = "dark"
    }
  }

  func testOnAppearKeepsCurrentThemeWhenNothingStored() async {
    let store = TestStore(initialState: ThemeSettings.State(userTheme: "light")) {
      ThemeSettings()
    } withDependencies: {
      $0.userDefaults.stringForKey = { _ in nil }
    }

    await store.send(.onAppear)
    XCTAssertEqual(store.state.userTheme, "light")
  }

  func testOnAppearIgnoresEmptyStoredTheme() async {
    let store = TestStore(initialState: ThemeSettings.State(userTheme: "light")) {
      ThemeSettings()
    } withDependencies: {
      $0.userDefaults.stringForKey = { _ in "" }
    }

    await store.send(.onAppear)
    XCTAssertEqual(store.state.userTheme, "light")
  }

  func testThemeChangedPersistsSelection() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: ThemeSettings.State()) {
      ThemeSettings()
    } withDependencies: {
      $0.userDefaults.setString = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.themeChanged("dark")) { $0.userTheme = "dark" }
    await store.finish()

    XCTAssertEqual(writes.value, ["user_theme=dark"])
  }

  func testDoneDismissesTheScreen() async {
    let didDismiss = LockIsolated(false)

    let store = TestStore(initialState: ThemeSettings.State()) {
      ThemeSettings()
    } withDependencies: {
      $0.dismiss = DismissEffect { didDismiss.setValue(true) }
    }

    await store.send(.done)
    await store.finish()

    XCTAssertTrue(didDismiss.value)
  }
}
