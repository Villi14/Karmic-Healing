//
// Karmic Healing 2026
//

import LocalAuthentication
import XCTest
@testable import Common

/// The seam between LocalAuthentication and the lock screen. Everything past it is reasoned
/// about in the app's own terms, so this is the one place the framework's own vocabulary has
/// to be read correctly.
final class BiometricsClientTests: XCTestCase {
  // MARK: - Reading the answer

  func testAnAnsweredPromptIsASuccess() {
    XCTAssertEqual(BiometricsOutcome(success: true, error: nil), .success)
  }

  /// Dismissing the prompt is a choice, and the lock screen treats it differently from a face
  /// it could not recognise — it stops asking rather than accusing.
  func testTheWaysOfSayingNotNowAreCancellations() {
    for code in [LAError.userCancel, .systemCancel, .appCancel] {
      XCTAssertEqual(
        BiometricsOutcome(success: false, error: LAError(code)),
        .cancelled,
        "\(code) was not read as a cancellation"
      )
    }
  }

  func testEveryOtherRefusalIsAFailure() {
    for code in [LAError.authenticationFailed, .biometryLockout, .biometryNotAvailable, .userFallback, .passcodeNotSet] {
      XCTAssertEqual(
        BiometricsOutcome(success: false, error: LAError(code)),
        .failed,
        "\(code) was excused as a cancellation"
      )
    }
  }

  func testARefusalWithNoErrorAtAllIsStillAFailure() {
    XCTAssertEqual(BiometricsOutcome(success: false, error: nil), .failed)
    XCTAssertEqual(BiometricsOutcome(success: false, error: CocoaError(.fileNoSuchFile)), .failed)
  }

  // MARK: - Asking the question

  func testEachPolicyAsksTheFrameworkForWhatItMeans() {
    XCTAssertEqual(BiometricsPolicy.biometricsOnly.laPolicy, .deviceOwnerAuthenticationWithBiometrics)
    XCTAssertEqual(BiometricsPolicy.deviceOwner.laPolicy, .deviceOwnerAuthentication)
  }

  func testTheBiometricsTheDeviceOffersAreNamed() {
    XCTAssertEqual(Biometry(.faceID), .faceID)
    XCTAssertEqual(Biometry(.touchID), .touchID)
    XCTAssertEqual(Biometry(.opticID), .opticID)
    XCTAssertEqual(Biometry(.none), Biometry.none)
  }

  // MARK: - The stand-in

  func testADeviceWithNothingToOfferRefusesEverything() async {
    let client = BiometricsClient.unavailable

    XCTAssertEqual(client.biometry(), Biometry.none)
    XCTAssertFalse(client.canEvaluate(.biometricsOnly))
    XCTAssertFalse(client.canEvaluate(.deviceOwner))

    let outcome = await client.evaluate(.biometricsOnly, "")
    XCTAssertEqual(outcome, .failed)
  }
}
