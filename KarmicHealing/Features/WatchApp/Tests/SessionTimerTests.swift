//
// Karmic Healing 2025
//

import Foundation
import XCTest
@testable import KarmicHealingWatch

final class SessionTimerTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_000_000)

  func testStoredMinutesFallBackToTheDefault() {
    XCTAssertEqual(SessionTimer.duration(fromStoredMinutes: 0), 300)
    XCTAssertEqual(SessionTimer.duration(fromStoredMinutes: -3), 300)
    XCTAssertEqual(SessionTimer.duration(fromStoredMinutes: 3), 180)
  }

  func testRemainingCountsDownWithWallClock() {
    let timer = SessionTimer(minutes: 5, startedAt: start)

    XCTAssertEqual(timer.remaining(at: start), 300)
    XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(120)), 180)
    // Never negative, however long the app was away.
    XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(9_999)), 0)
  }

  func testProgressRunsFromZeroToOne() {
    let timer = SessionTimer(minutes: 5, startedAt: start)

    XCTAssertEqual(timer.progress(at: start), 0)
    XCTAssertEqual(timer.progress(at: start.addingTimeInterval(150)), 0.5, accuracy: 0.001)
    XCTAssertEqual(timer.progress(at: start.addingTimeInterval(600)), 1)
  }

  func testOneStepIsConsumedWhenItsTimeIsUp() {
    var timer = SessionTimer(minutes: 5, startedAt: start)

    XCTAssertEqual(timer.consumeElapsedSteps(at: start.addingTimeInterval(299)), 0)
    XCTAssertEqual(timer.consumeElapsedSteps(at: start.addingTimeInterval(300)), 1)
    // The anchor moved with it, so the next step gets its full length.
    XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(300)), 300)
  }

  func testTimeSpentInTheBackgroundIsCaughtUpInOneMove() {
    var timer = SessionTimer(minutes: 5, startedAt: start)

    // Twenty-two minutes away: four whole steps elapsed, two minutes into the fifth.
    XCTAssertEqual(timer.consumeElapsedSteps(at: start.addingTimeInterval(22 * 60)), 4)
    XCTAssertEqual(timer.remaining(at: start.addingTimeInterval(22 * 60)), 180)
  }

  func testPausingFreezesTheRemainderAndResumingRestoresIt() {
    var timer = SessionTimer(minutes: 5, startedAt: start)
    let pausedAt = start.addingTimeInterval(120)

    timer.pause(at: pausedAt)
    XCTAssertTrue(timer.isPaused)
    // Time passing while paused must not move the session on.
    XCTAssertEqual(timer.remaining(at: pausedAt.addingTimeInterval(3_600)), 180)
    XCTAssertEqual(timer.consumeElapsedSteps(at: pausedAt.addingTimeInterval(3_600)), 0)

    let resumedAt = pausedAt.addingTimeInterval(3_600)
    timer.resume(at: resumedAt)
    XCTAssertFalse(timer.isPaused)
    XCTAssertEqual(timer.remaining(at: resumedAt), 180)
    XCTAssertEqual(timer.consumeElapsedSteps(at: resumedAt.addingTimeInterval(180)), 1)
  }

  func testRestartGivesTheStepItsFullLengthAgain() {
    var timer = SessionTimer(minutes: 5, startedAt: start)
    let scrolledAt = start.addingTimeInterval(290)

    timer.restart(at: scrolledAt)
    XCTAssertEqual(timer.remaining(at: scrolledAt), 300)
    XCTAssertEqual(timer.consumeElapsedSteps(at: scrolledAt.addingTimeInterval(299)), 0)
  }

  func testChangingTheDurationAppliesFromNow() {
    var timer = SessionTimer(minutes: 5, startedAt: start)
    let changedAt = start.addingTimeInterval(60)

    timer.setDuration(SessionTimer.duration(fromStoredMinutes: 1), at: changedAt)
    XCTAssertEqual(timer.remaining(at: changedAt), 60)
    XCTAssertEqual(timer.consumeElapsedSteps(at: changedAt.addingTimeInterval(60)), 1)
  }
}
