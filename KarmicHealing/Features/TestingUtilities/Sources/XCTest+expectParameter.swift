//
// Karmic Healing 2025
//

import Foundation
import XCTest

extension XCTestCase {
  /// A helper to assert that a parameter equals a specific value(s).
  public func expectParameter<T: Equatable>(
    _ current: T,
    expectedValues invocations: [T],
    closureID: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let key = ClosureKey(file: file, line: line, id: closureID)

    if let checker = self.closureParameters[key] {
      checker.checkExpectedValuesConsistency(invocations)
      self.closureParameters[key] = checker.byAdding(current)
      return
    }

    self.closureParameters[key] = .init(
      value: current,
      expectedValues: invocations,
      file: file,
      line: line
    )

    nonisolated(unsafe) let selfCopy = self
    self.addTeardownBlock {
      guard let checker = selfCopy.closureParameters[key] else {
        XCTFail("Something has wrong here. Cannot retrieve invocations parameters", file: file, line: line)
        return
      }

      checker.checkParameters()
    }
  }

  public func expectParameter<T: Equatable>(
    _ current: T,
    expectedValue invocation: T,
    closureID: String? = nil,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    self.expectParameter(
      current,
      expectedValues: [invocation],
      closureID: closureID,
      file: file,
      line: line
    )
  }
}

private struct ClosureKey: Hashable {
  let file: StaticString
  let line: UInt
  let id: String?

  static func == (lhs: ClosureKey, rhs: ClosureKey) -> Bool {
    if lhs.line != rhs.line {
      return false
    }

    if lhs.file.utf8Start != rhs.file.utf8Start {
      return false
    }

    if lhs.id != rhs.id {
      return false
    }

    return true
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.line)
    hasher.combine(self.file.utf8Start)
    hasher.combine(self.id)
  }
}

private struct ParametersChecker {
  private var invokedParameters: [Any]

  private var checkParametersClosure: (_ invocations: [Any]) -> Void

  private var checkExpectedValuesClosure: (_ invocations: [Any]) -> Void

  init<T: Equatable>(
    value: T,
    expectedValues: [T],
    file: StaticString,
    line: UInt
  ) {
    self.invokedParameters = [value]

    self.checkParametersClosure = { value in
      guard let value = value as? [T] else {
        XCTFail(
          "Internal error - cannot correctly cast parameters",
          file: file,
          line: line
        )
        return
      }

      XCTAssertEqual(value, expectedValues, file: file, line: line)
    }

    self.checkExpectedValuesClosure = { value in
      guard let value = value as? [T] else {
        XCTFail(
          "Internal error - cannot correctly cast expected values",
          file: file,
          line: line
        )
        return
      }

      XCTAssertEqual(
        value,
        expectedValues,
        "Inconsistent expected values - first: \(expectedValues), current: \(value)",
        file: file,
        line: line
      )
    }
  }

  func byAdding(_ value: Any) -> Self {
    var copy = self
    copy.invokedParameters.append(value)
    return copy
  }

  func checkExpectedValuesConsistency(_ expectedValues: [Any]) {
    return self.checkExpectedValuesClosure(expectedValues)
  }

  func checkParameters() {
    return self.checkParametersClosure(self.invokedParameters)
  }
}

extension XCTestCase {
  private func checkInvocations(
    expected: Int,
    actual: Int,
    file: StaticString,
    line: UInt
  ) {
    XCTAssertTrue(
      actual == expected,
      "Closure has not been invoked the correct amount of times. Expected: \(expected), current: \(actual)",
      file: file,
      line: line
    )
  }
  /// A variable that stores the amount of invocations for a specific closure
  private var closureParameters: [ClosureKey: ParametersChecker] {
    get {
      let parameters = withUnsafePointer(to: &checkInvocationsKey) {
        return objc_getAssociatedObject(self, $0) as? [ClosureKey: ParametersChecker]
      }
      if let parameters {
        return parameters
      }
      let newParameters = [ClosureKey: ParametersChecker]()
      self.closureParameters = newParameters
      return newParameters
    }

    set {
      withUnsafePointer(to: &checkInvocationsKey) {
        return objc_setAssociatedObject(self, $0, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      }
    }
  }
}

private nonisolated(unsafe) var checkInvocationsKey = "testing_utilities_expect_parameter"
