//
// Karmic Healing 2026
//

import Foundation
import XCTest
@testable import Common

/// The code is the app's answer to a face that will not be recognised, so what these check is
/// that it recognises the right digits, refuses every other four, gives nothing away about
/// itself in storage, and does not sit still to be guessed at.
final class PasscodeTests: XCTestCase {
  // MARK: - The digest

  func testADigestRecognisesTheCodeItWasMadeFrom() {
    let digest = PasscodeDigest(code: "2718")

    XCTAssertTrue(digest.matches("2718"))
  }

  func testADigestRefusesEveryOtherCode() {
    let digest = PasscodeDigest(code: "2718")

    for candidate in ["2719", "1728", "271", "27180", "", "abcd"] {
      XCTAssertFalse(digest.matches(candidate), "'\(candidate)' was taken for 2718")
    }
  }

  func testTheStoredDigestIsNotTheCode() throws {
    let digest = PasscodeDigest(code: "2718")
    let stored = try XCTUnwrap(String(data: JSONEncoder().encode(digest), encoding: .utf8))

    XCTAssertFalse(stored.contains("2718"), "The code itself is readable in what is stored")
  }

  /// Four digits are ten thousand possibilities — few enough that one shared hash would be a
  /// lookup table away from every code in it.
  func testTheSameCodeSaltsDifferentlyEachTime() {
    let first = PasscodeDigest(code: "2718")
    let second = PasscodeDigest(code: "2718")

    XCTAssertNotEqual(first.salt, second.salt)
    XCTAssertNotEqual(first.hash, second.hash)
    XCTAssertTrue(second.matches("2718"))
  }

  func testADigestSurvivesBeingStoredAndReadBack() throws {
    let digest = PasscodeDigest(code: "2718")
    let restored = try JSONDecoder().decode(PasscodeDigest.self, from: JSONEncoder().encode(digest))

    XCTAssertEqual(restored, digest)
    XCTAssertTrue(restored.matches("2718"))
  }

  // MARK: - The client

  func testNoCodeIsSetUntilOneIsSaved() {
    let client = PasscodeClient.inMemory()

    XCTAssertFalse(client.isSet())
    XCTAssertFalse(client.verify("0000"))

    client.save("2718")

    XCTAssertTrue(client.isSet())
  }

  func testASavedCodeIsTheOnlyOneThatVerifies() {
    let client = PasscodeClient.inMemory()
    client.save("2718")

    XCTAssertTrue(client.verify("2718"))
    XCTAssertFalse(client.verify("8172"))
  }

  func testSavingAgainReplacesTheCode() {
    let client = PasscodeClient.inMemory()
    client.save("2718")
    client.save("3141")

    XCTAssertFalse(client.verify("2718"))
    XCTAssertTrue(client.verify("3141"))
  }

  func testClearingLeavesNoCodeBehind() {
    let client = PasscodeClient.inMemory()
    client.save("2718")
    client.clear()

    XCTAssertFalse(client.isSet())
    XCTAssertFalse(client.verify("2718"))
  }

  func testTheCodeIsFourDigitsLong() {
    XCTAssertEqual(PasscodeClient.length, 4)
  }

  // MARK: - Wrong codes

  func testMistypingIsForgivenUpToTheAllowance() {
    let now = Date()
    var attempts = PasscodeAttempts()

    for _ in 0..<PasscodeAttempts.allowance {
      attempts.recordFailure(at: now)
      XCTAssertFalse(attempts.isWaiting(at: now))
    }
  }

  func testTheFirstWrongCodePastTheAllowanceCostsAWait() {
    let now = Date()
    var attempts = PasscodeAttempts()

    for _ in 0...PasscodeAttempts.allowance {
      attempts.recordFailure(at: now)
    }

    XCTAssertTrue(attempts.isWaiting(at: now))
    XCTAssertEqual(attempts.remainingWait(at: now), Int(PasscodeAttempts.penalties[0]))
  }

  func testEachFurtherWrongCodeCostsMore() {
    let now = Date()
    var attempts = PasscodeAttempts()
    var waits: [Int] = []

    for attempt in 1...(PasscodeAttempts.allowance + PasscodeAttempts.penalties.count + 1) {
      attempts.recordFailure(at: now)
      guard attempt > PasscodeAttempts.allowance else { continue }
      waits.append(attempts.remainingWait(at: now))
    }

    XCTAssertEqual(waits, PasscodeAttempts.penalties.map(Int.init) + [Int(PasscodeAttempts.penalties.last!)])
  }

  func testTheWaitRunsOutWithTime() {
    let now = Date()
    var attempts = PasscodeAttempts()

    for _ in 0...PasscodeAttempts.allowance {
      attempts.recordFailure(at: now)
    }

    let penalty = PasscodeAttempts.penalties[0]
    XCTAssertEqual(attempts.remainingWait(at: now.addingTimeInterval(penalty - 10)), 10)
    XCTAssertFalse(attempts.isWaiting(at: now.addingTimeInterval(penalty)))
  }

  func testTheRightCodeGivesTheFullAllowanceBack() {
    let now = Date()
    var attempts = PasscodeAttempts()

    for _ in 0...(PasscodeAttempts.allowance + 2) {
      attempts.recordFailure(at: now)
    }
    attempts.recordSuccess()

    XCTAssertEqual(attempts, PasscodeAttempts())
    XCTAssertFalse(attempts.isWaiting(at: now))

    attempts.recordFailure(at: now)
    XCTAssertFalse(attempts.isWaiting(at: now), "A single mistype after the right code costs a wait")
  }
}
