//
// Karmic Healing 2025
//

import ConcurrencyExtras
import XCTest

extension XCTestCase {
  /// Repeats the given closure signature and asserts on the number of times it is called during a test run.
  public func withTrackedCalls<each Input, Output>(
    count callsCount: Int,
    _ closure: @escaping (_ inputs: repeat each Input) -> Output,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> @Sendable (repeat each Input) -> Output {
    let actualCallsCount: LockIsolated<Int> = .init(0)

    addTeardownBlock {
      XCTAssertEqual(
        actualCallsCount.value,
        callsCount,
        "The closure was not called to expected amount of times",
        file: file,
        line: line
      )
    }

    return { (inputs: repeat each Input) in
      actualCallsCount.withValue { $0 += 1 }
      return closure(repeat each inputs)
    }
  }

  /// Repeats the given closure signature and asserts on the number of times it is called during a test run.
  public func withTrackedCalls<each Input, Output>(
    count callsCount: Int,
    _ closure: @escaping (_ inputs: repeat each Input) throws -> Output,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> @Sendable (repeat each Input) throws -> Output {
    let actualCallsCount: LockIsolated<Int> = .init(0)

    addTeardownBlock {
      XCTAssertEqual(
        actualCallsCount.value,
        callsCount,
        "The closure was not called to expected amount of times",
        file: file,
        line: line
      )
    }

    return { (inputs: repeat each Input) in
      actualCallsCount.withValue { $0 += 1 }
      return try closure(repeat each inputs)
    }
  }
}
