//
// Karmic Healing 2026
//

import Common
import Dependencies
import Foundation
import XCTest
@testable import KarmicHealing

/// The lock screen's reasoning, with the device's answers put in by hand.
///
/// What matters here is which proof the app asks for and what it makes of the answer: asking
/// for the wrong one puts the system's own passcode field in front of the user, and reading an
/// answer wrongly either locks the owner out or lets a stranger in.
@MainActor
final class AppLockTests: XCTestCase {
  // MARK: - Which proof is asked for

  func testALockWithACodeAsksForBiometricsAlone() async {
    let device = Device(biometry: .faceID, evaluable: [.biometricsOnly, .deviceOwner])
    let controller = makeController(device: device, passcode: "2718")

    await controller.authenticate()

    XCTAssertEqual(device.asked, [.biometricsOnly])
  }

  /// The regression this all turns on: a lock switched on before codes existed has no code of
  /// its own yet, and asking the device for anything it will accept lands the user on the
  /// system's passcode screen the moment the app opens.
  func testALockWithoutACodeStillAsksForBiometricsAlone() async {
    let device = Device(biometry: .faceID, evaluable: [.biometricsOnly, .deviceOwner])
    let controller = makeController(device: device, passcode: nil)

    await controller.authenticate()

    XCTAssertEqual(device.asked, [.biometricsOnly])
    XCTAssertFalse(device.asked.contains(.deviceOwner), "The system's own passcode screen was asked for")
  }

  /// Without biometrics and without a code there is no other door: the device itself has to be
  /// the one to ask, or the owner cannot get in to choose a code at all.
  func testWithoutBiometricsOrACodeTheDeviceItselfIsAsked() async {
    let device = Device(biometry: .none, evaluable: [.deviceOwner])
    let controller = makeController(device: device, passcode: nil)

    await controller.authenticate()

    XCTAssertEqual(device.asked, [.deviceOwner])
  }

  func testWithoutBiometricsTheKeypadIsGoneToWithoutAnyPrompt() async {
    let device = Device(biometry: .none, evaluable: [.deviceOwner])
    let controller = makeController(device: device, passcode: "2718")

    await controller.authenticate()

    XCTAssertEqual(device.asked, [], "A prompt was put up when the keypad was the way in")
    XCTAssertEqual(controller.stage, .passcode)
  }

  func testADeviceThatCanAskNothingSaysSo() async {
    let device = Device(biometry: .none, evaluable: [])
    let controller = makeController(device: device, passcode: nil)

    await controller.authenticate()

    XCTAssertEqual(controller.errorMessage, "app_lock_unavailable".loc)
    XCTAssertFalse(controller.isUnlocked)
  }

  // MARK: - What the answer means

  func testTheRightFaceOpensAnAppThatHasACode() async {
    let controller = makeController(device: Device(outcome: .success), passcode: "2718")

    await controller.authenticate()

    XCTAssertTrue(controller.isUnlocked)
    XCTAssertFalse(controller.isAuthenticating)
  }

  /// The one launch a code-less lock still opens the old way — and it opens onto choosing a code.
  func testTheRightFaceWithoutACodeAsksForOneToBeChosen() async {
    let controller = makeController(device: Device(outcome: .success), passcode: nil)

    await controller.authenticate()

    XCTAssertEqual(controller.stage, .creatingPasscode)
    XCTAssertFalse(controller.isUnlocked, "The app opened without a code ever being chosen")
  }

  func testAFaceNotRecognisedLeavesTheKeypad() async {
    let controller = makeController(device: Device(outcome: .failed), passcode: "2718")

    await controller.authenticate()

    XCTAssertEqual(controller.stage, .passcode)
    XCTAssertNil(controller.passcodeMessage, "The keypad accused the user before a code was typed")
    XCTAssertFalse(controller.isUnlocked)
  }

  func testWavingThePromptAwayAlsoLeavesTheKeypad() async {
    let controller = makeController(device: Device(outcome: .cancelled), passcode: "2718")

    await controller.authenticate()

    XCTAssertEqual(controller.stage, .passcode)
  }

  /// With no keypad to fall back on, dismissing the prompt has to leave the unlock button
  /// rather than an accusation.
  func testWavingThePromptAwayWithoutACodeIsNotAFailure() async {
    let controller = makeController(device: Device(outcome: .cancelled), passcode: nil)

    await controller.authenticate()

    XCTAssertEqual(controller.stage, .biometrics)
    XCTAssertNil(controller.errorMessage)
  }

  func testAFailureWithoutACodeIsSaidOutLoud() async {
    let controller = makeController(device: Device(outcome: .failed), passcode: nil)

    await controller.authenticate()

    XCTAssertEqual(controller.errorMessage, "app_lock_failed".loc)
    XCTAssertEqual(controller.stage, .biometrics)
  }

  // MARK: - Asking again, or not

  func testAPromptWavedAwayIsNotPutStraightBackUp() async {
    let device = Device(outcome: .cancelled)
    let controller = makeController(device: device, passcode: nil)

    await controller.authenticateIfNeeded()
    await controller.authenticateIfNeeded()

    XCTAssertEqual(device.asked.count, 1, "Returning to the app put the dismissed prompt back up")
  }

  func testLockingAgainRestoresTheAskingAfterACancellation() async {
    let device = Device(outcome: .cancelled)
    let controller = makeController(device: device, passcode: nil)

    await controller.authenticateIfNeeded()
    controller.lock()
    await controller.authenticateIfNeeded()

    XCTAssertEqual(device.asked.count, 2)
  }

  func testAnOpenAppIsNotAskedToProveItselfAgain() async {
    let device = Device(outcome: .success)
    let controller = makeController(device: device, passcode: "2718")

    await controller.authenticateIfNeeded()
    await controller.authenticateIfNeeded()

    XCTAssertEqual(device.asked.count, 1)
  }

  func testLockingCloseTheAppAndForgetsWhereTheUserWas() async {
    let controller = makeController(device: Device(outcome: .success), passcode: "2718")
    await controller.authenticate()

    controller.lock()

    XCTAssertFalse(controller.isUnlocked)
    XCTAssertEqual(controller.stage, .biometrics)
  }

  func testTurningTheLockOnFromInsideDoesNotAskAnything() async {
    let device = Device(outcome: .success)
    let controller = makeController(device: device, passcode: "2718")

    controller.unlockWithoutPrompt()

    XCTAssertTrue(controller.isUnlocked)
    XCTAssertEqual(device.asked, [])
  }

  // MARK: - The keypad

  func testTheRightCodeOpensTheApp() async {
    let controller = makeController(device: Device(outcome: .failed), passcode: "2718")
    await controller.authenticate()

    XCTAssertTrue(controller.submit("2718"))
    XCTAssertTrue(controller.isUnlocked)
    XCTAssertNil(controller.passcodeMessage)
  }

  func testAWrongCodeSaysSoAndKeepsTheAppShut() async {
    let controller = makeController(device: Device(outcome: .failed), passcode: "2718")
    await controller.authenticate()

    XCTAssertFalse(controller.submit("1234"))
    XCTAssertFalse(controller.isUnlocked)
    XCTAssertEqual(controller.passcodeMessage, "passcode_wrong".loc)
  }

  func testGuessingIsMadeToWaitAndTheWaitIsRefusedCodes() async {
    let now = Date()
    let controller = makeController(device: Device(outcome: .failed), passcode: "2718")
    await controller.authenticate()

    for _ in 0...PasscodeAttempts.allowance {
      XCTAssertFalse(controller.submit("1234", now: now))
    }

    XCTAssertGreaterThan(controller.remainingWait(at: now), 0)
    XCTAssertFalse(controller.submit("2718", now: now), "The right code was taken during the wait")
    XCTAssertFalse(controller.isUnlocked)
  }

  func testTheWaitEndsAndTheRightCodeIsTakenAgain() async {
    let now = Date()
    let controller = makeController(device: Device(outcome: .failed), passcode: "2718")
    await controller.authenticate()

    for _ in 0...PasscodeAttempts.allowance {
      _ = controller.submit("1234", now: now)
    }

    let later = now.addingTimeInterval(TimeInterval(controller.remainingWait(at: now)))

    XCTAssertTrue(controller.submit("2718", now: later))
    XCTAssertTrue(controller.isUnlocked)
  }

  /// Wrong codes are the controller's to remember: locking and coming back is no way out of a wait.
  func testAWaitOutlastsALocking() async {
    let now = Date()
    let controller = makeController(device: Device(outcome: .failed), passcode: "2718")
    await controller.authenticate()

    for _ in 0...PasscodeAttempts.allowance {
      _ = controller.submit("1234", now: now)
    }
    controller.lock()

    XCTAssertGreaterThan(controller.remainingWait(at: now), 0)
  }

  // MARK: - A forgotten code

  func testAForgottenCodeIsReplacedOnceTheDeviceItselfIsSatisfied() async {
    let device = Device(evaluable: [.deviceOwner], outcome: .success)
    let controller = makeController(device: device, passcode: "2718")

    await controller.resetPasscode()

    XCTAssertEqual(device.asked, [.deviceOwner], "Anything less than the device itself let a code be replaced")
    XCTAssertEqual(controller.stage, .creatingPasscode)
  }

  func testAForgottenCodeIsNotReplacedWhenTheDeviceRefuses() async {
    let device = Device(evaluable: [.deviceOwner], outcome: .failed)
    let controller = makeController(device: device, passcode: "2718")

    await controller.resetPasscode()

    XCTAssertEqual(controller.stage, .biometrics)
    XCTAssertEqual(controller.passcodeMessage, "app_lock_failed".loc)
  }

  func testBackingOutOfReplacingACodeSaysNothing() async {
    let device = Device(evaluable: [.deviceOwner], outcome: .cancelled)
    let controller = makeController(device: device, passcode: "2718")

    await controller.resetPasscode()

    XCTAssertNil(controller.passcodeMessage)
  }

  // MARK: - What the screen shows

  func testTheIconFollowsWhatTheDeviceOffers() {
    XCTAssertEqual(makeController(device: Device(biometry: .faceID)).biometryIconName, "faceid")
    XCTAssertEqual(makeController(device: Device(biometry: .touchID)).biometryIconName, "touchid")
    XCTAssertEqual(makeController(device: Device(biometry: .none)).biometryIconName, "lock.fill")
  }

  func testTheKeypadOffersBiometricsBackOnlyWhenThereAreSome() {
    XCTAssertTrue(makeController(device: Device(biometry: .faceID)).canOfferBiometrics)
    XCTAssertFalse(makeController(device: Device(biometry: .none)).canOfferBiometrics)
  }

  // MARK: - Helpers

  private func makeController(device: Device, passcode code: String? = nil) -> AppLockController {
    withDependencies {
      $0.biometrics = device.client
      $0.passcode = {
        let client = PasscodeClient.inMemory()
        if let code { client.save(code) }
        return client
      }()
    } operation: {
      AppLockController()
    }
  }
}

/// A device that answers however the test needs it to, and remembers what it was asked.
private final class Device: @unchecked Sendable {
  private let biometry: Biometry
  private let evaluable: [BiometricsPolicy]
  private let outcome: BiometricsOutcome

  private let lock = NSLock()
  private var promptedFor: [BiometricsPolicy] = []

  init(
    biometry: Biometry = .faceID,
    evaluable: [BiometricsPolicy] = [.biometricsOnly, .deviceOwner],
    outcome: BiometricsOutcome = .success
  ) {
    self.biometry = biometry
    self.evaluable = evaluable
    self.outcome = outcome
  }

  /// Every prompt this device was actually made to put up, in order.
  var asked: [BiometricsPolicy] {
    lock.withLock { promptedFor }
  }

  var client: BiometricsClient {
    BiometricsClient(
      biometry: { [biometry] in biometry },
      canEvaluate: { [evaluable] policy in evaluable.contains(policy) },
      // Held strongly: the client outlives the `Device(...)` a test hands over in passing,
      // and a device that has been let go answers nothing.
      evaluate: { policy, _ in
        self.lock.withLock { self.promptedFor.append(policy) }
        return self.outcome
      }
    )
  }
}
