//
// Karmic Healing 2025
//

import XCTest
import ComposableArchitecture
@testable import Home

@MainActor
final class HomeTests: XCTestCase {
  func testDidTapSettingsButton() async {
    let store = TestStore(initialState: Home.State()) {
      Home()
    }
  }

  func testDidTapFlowButtons() async {
    let store = TestStore(initialState: Home.State()) {
      Home()
    }
  }
}
