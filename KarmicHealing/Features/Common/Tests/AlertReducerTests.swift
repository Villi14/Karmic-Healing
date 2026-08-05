//
// Karmic Healing 2025
//

import ComposableArchitecture
import XCTest
@testable import Common

private enum AlertAction: Equatable {
  case retry
  case cancel
}

@MainActor
final class AlertReducerTests: XCTestCase {
  func testAlertGetsDefaultOkButtonWhenNoneProvided() {
    let state = AlertReducer<AlertAction>.State(title: "Title")

    XCTAssertEqual(state.buttons.count, 1)
    XCTAssertEqual(state.buttons.first?.label, "OK")
    XCTAssertNil(state.buttons.first?.action)
    XCTAssertEqual(state.style, .default)
  }

  func testProvidedButtonsAreKept() {
    let state = AlertReducer<AlertAction>.State(
      title: "Title",
      buttons: [
        .init(label: "Retry", action: .retry),
        .init(label: "Cancel", action: .cancel, role: .cancel)
      ]
    )

    XCTAssertEqual(state.buttons.map(\.label), ["Retry", "Cancel"])
    XCTAssertEqual(state.buttons.map(\.action), [.retry, .cancel])
    XCTAssertEqual(state.buttons.last?.role, .cancel)
  }

  func testBuilderInitializerForwardsAllValues() {
    let state = AlertReducer<AlertAction>.State(
      title: { "Title" },
      message: { "Message" },
      buttons: { [.init(label: "Retry", action: .retry)] },
      style: .warning
    )

    XCTAssertEqual(state.title, "Title")
    XCTAssertEqual(state.message, "Message")
    XCTAssertEqual(state.buttons.map(\.label), ["Retry"])
    XCTAssertEqual(state.style, .warning)
  }

  func testConvenienceInitializersUseMatchingStyles() {
    XCTAssertEqual(AlertReducer<AlertAction>.State.success(title: "t").style, .success)
    XCTAssertEqual(AlertReducer<AlertAction>.State.error(title: "t").style, .error)
    XCTAssertEqual(AlertReducer<AlertAction>.State.warning(title: "t").style, .warning)
    XCTAssertEqual(AlertReducer<AlertAction>.State.info(title: "t").style, .info)
  }

  func testButtonEqualityIgnoresIdentifier() {
    let first = AlertReducer<AlertAction>.State.ButtonState(label: "Retry", action: .retry)
    let second = AlertReducer<AlertAction>.State.ButtonState(label: "Retry", action: .retry)

    XCTAssertNotEqual(first.id, second.id)
    XCTAssertEqual(first, second)
  }

  func testReducerHasNoEffects() async {
    let store = TestStore(initialState: AlertReducer<AlertAction>.State(title: "Title")) {
      AlertReducer<AlertAction>()
    }

    await store.send(.retry)
    await store.finish()
  }
}
