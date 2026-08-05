//
// Karmic Healing 2025
//

import ComposableArchitecture
import XCTest
@testable import BalancingEnergyList

@MainActor
final class BalancingEnergyHelpTests: XCTestCase {
  func testDismissButtonSendsDismiss() async {
    let store = TestStore(initialState: BalancingEnergyHelp.State(isPresented: true)) {
      BalancingEnergyHelp()
    }

    await store.send(.dismissButtonTapped)
    await store.receive(.dismiss)
  }

  func testOnAppearHasNoEffect() async {
    let store = TestStore(initialState: BalancingEnergyHelp.State()) {
      BalancingEnergyHelp()
    }

    await store.send(.onAppear)
    XCTAssertFalse(store.state.isPresented)
  }
}
