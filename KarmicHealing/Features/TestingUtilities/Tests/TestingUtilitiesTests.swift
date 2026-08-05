//
// Karmic Healing 2025
//

import CoreMedia
import Foundation
import XCTest
@testable import TestingUtilities

final class TestingUtilitiesTests: XCTestCase {
  func testWithTrackedCallsForwardsArgumentsAndReturnValue() {
    let doubled = withTrackedCalls(count: 2) { (value: Int) -> Int in value * 2 }

    XCTAssertEqual(doubled(2), 4)
    XCTAssertEqual(doubled(21), 42)
    // The expected call count is verified in the teardown block.
  }

  func testWithTrackedCallsSupportsThrowingClosures() throws {
    struct Failure: Error {}
    let closure = withTrackedCalls(count: 2) { (shouldThrow: Bool) throws -> String in
      if shouldThrow { throw Failure() }
      return "ok"
    }

    XCTAssertEqual(try closure(false), "ok")
    XCTAssertThrowsError(try closure(true))
  }

  func testWithTrackedCallsSupportsClosuresWithoutArguments() {
    let closure = withTrackedCalls(count: 1) { () -> Void in }

    closure()
  }

  func testExpectParameterCollectsInvocationsInOrder() {
    let closure = { (value: Int) in
      self.expectParameter(value, expectedValues: [1, 2, 3], closureID: "ordered")
    }

    closure(1)
    closure(2)
    closure(3)
    // The collected parameters are compared in the teardown block.
  }

  func testExpectParameterWithASingleExpectedValue() {
    expectParameter("karmic", expectedValue: "karmic", closureID: "single")
  }

  func testCMTimeFloatLiteralUsesSixHundredTimescale() {
    let time: CMTime = 1.5

    XCTAssertEqual(time.seconds, 1.5)
    XCTAssertEqual(time.timescale, 600)
  }

  func testCMTimeIntegerLiteral() {
    let time: CMTime = 3

    XCTAssertEqual(time.seconds, 3)
    XCTAssertEqual(time.timescale, 600)
  }
}
