//
// Karmic Healing 2025
//

import XCTest
@testable import BalancingEnergy

final class StepsTests: XCTestCase {
  func testPartsHaveTheExpectedNumberOfSteps() {
    XCTAssertEqual(Step.part1.count, 14)
    XCTAssertEqual(Step.part2.count, 12)
    XCTAssertEqual(Step.part3.count, 18)
  }

  func testAllPartsShareTheSameOpeningSteps() {
    for part in [Step.part1, Step.part2, Step.part3] {
      XCTAssertEqual(Array(part.prefix(3)), [.step1, .step2, .step3])
    }
  }

  func testNoStepHasAnEmptyTitle() {
    for part in [Step.part1, Step.part2, Step.part3] {
      XCTAssertFalse(part.contains { $0.title.isEmpty })
    }
  }

  func testDescriptionDefaultsToEmptyString() {
    XCTAssertEqual(Step(title: "title").description, "")
    XCTAssertEqual(Step(title: "title", description: "body").description, "body")
  }

  func testEssentialAndDivineSelfShareTheirFirstTenSteps() {
    XCTAssertEqual(Array(Step.part2.prefix(10)), Array(Step.part3.prefix(10)))
  }
}
