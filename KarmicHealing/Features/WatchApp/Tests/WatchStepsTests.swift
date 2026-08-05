//
// Karmic Healing 2025
//

import XCTest
@testable import KarmicHealingWatch

/// The watch carries its own copy of the steps, and it offers only the two later parts — the
/// initial process stays on the phone.
final class WatchStepsTests: XCTestCase {
  func testThePartsTheWatchOffersHaveTheExpectedNumberOfSteps() {
    XCTAssertEqual(Step.part2.count, 12)
    XCTAssertEqual(Step.part3.count, 18)
  }

  func testBothPartsOpenTheSameWay() {
    for part in [Step.part2, Step.part3] {
      XCTAssertEqual(Array(part.prefix(3)), [.step1, .step2, .step3])
    }
  }

  func testEssentialAndDivineSelfShareTheirFirstTenSteps() {
    XCTAssertEqual(Array(Step.part2.prefix(10)), Array(Step.part3.prefix(10)))
  }

  func testBothPartsCloseOnTheSameStep() {
    for part in [Step.part2, Step.part3] {
      XCTAssertEqual(part.last, .stepLast)
    }
  }

  func testNoStepHasAnEmptyTitle() {
    for part in [Step.part2, Step.part3] {
      XCTAssertFalse(part.contains { $0.title.isEmpty })
    }
  }

  /// Only the third step carries a body — every other slide is its title alone.
  func testOnlyTheThirdStepCarriesADescription() {
    for part in [Step.part2, Step.part3] {
      XCTAssertEqual(part.filter { !$0.description.isEmpty }, [.step3])
    }
  }

  func testDescriptionDefaultsToEmptyString() {
    XCTAssertEqual(Step(title: "title").description, "")
    XCTAssertEqual(Step(title: "title", description: "body").description, "body")
  }

  /// The watch steps are the same steps the phone runs, so the two copies must not drift apart
  /// in length.
  func testTheWatchStepsMatchWhatTheMeditationTypesOffer() {
    XCTAssertEqual(MeditationType.essential.steps.count, Step.part2.count)
    XCTAssertEqual(MeditationType.divine.steps.count, Step.part3.count)
  }
}
