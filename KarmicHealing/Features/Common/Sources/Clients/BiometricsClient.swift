//
// Karmic Healing 2026
//

import Dependencies
import Foundation
import LocalAuthentication

extension DependencyValues {
  public var biometrics: BiometricsClient {
    get { self[BiometricsClient.self] }
    set { self[BiometricsClient.self] = newValue }
  }
}

/// The device asking, on the app's behalf, whether the person holding it is its owner.
///
/// LocalAuthentication answers only from a real device with a real face in front of it, which
/// is no answer at all to a test. Behind this client the lock screen's reasoning — which proof
/// to ask for, and what each answer means — can be run without any of that.
public struct BiometricsClient: Sendable {
  /// What the device offers, if anything.
  public var biometry: @Sendable () -> Biometry
  /// Whether this proof could be asked for at all, at this moment.
  public var canEvaluate: @Sendable (BiometricsPolicy) -> Bool
  /// Puts the system prompt up and waits for it to be answered.
  public var evaluate: @Sendable (BiometricsPolicy, String) async -> BiometricsOutcome

  public init(
    biometry: @escaping @Sendable () -> Biometry,
    canEvaluate: @escaping @Sendable (BiometricsPolicy) -> Bool,
    evaluate: @escaping @Sendable (BiometricsPolicy, String) async -> BiometricsOutcome
  ) {
    self.biometry = biometry
    self.canEvaluate = canEvaluate
    self.evaluate = evaluate
  }
}

/// Which of the device's own biometrics is on offer.
public enum Biometry: Equatable, Sendable {
  case none
  case touchID
  case faceID
  case opticID
}

/// What the app is willing to accept as proof of the owner.
public enum BiometricsPolicy: Equatable, Sendable {
  /// Face ID or Touch ID and nothing besides.
  case biometricsOnly
  /// Whatever the device itself accepts, its own passcode screen included.
  case deviceOwner
}

/// How the asking ended.
public enum BiometricsOutcome: Equatable, Sendable {
  case success
  /// The prompt was waved away rather than answered — a choice, not a failure.
  case cancelled
  case failed
}

extension BiometricsClient: DependencyKey {
  public static let liveValue = BiometricsClient(
    biometry: {
      let context = LAContext()
      // The type is only filled in once the context has been asked what it can do.
      _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
      return Biometry(context.biometryType)
    },
    canEvaluate: { policy in
      LAContext().canEvaluatePolicy(policy.laPolicy, error: nil)
    },
    evaluate: { policy, reason in
      await withCheckedContinuation { continuation in
        LAContext().evaluatePolicy(policy.laPolicy, localizedReason: reason) { success, error in
          continuation.resume(returning: BiometricsOutcome(success: success, error: error))
        }
      }
    }
  )

  public static var testValue: BiometricsClient { .unavailable }
  public static var previewValue: BiometricsClient { .unavailable }

  /// A device with nothing to offer — what a test or a preview gets until it says otherwise.
  public static let unavailable = BiometricsClient(
    biometry: { .none },
    canEvaluate: { _ in false },
    evaluate: { _, _ in .failed }
  )
}

// MARK: - Speaking LocalAuthentication

extension BiometricsPolicy {
  var laPolicy: LAPolicy {
    switch self {
    case .biometricsOnly: .deviceOwnerAuthenticationWithBiometrics
    case .deviceOwner: .deviceOwnerAuthentication
    }
  }
}

extension Biometry {
  init(_ type: LABiometryType) {
    switch type {
    case .touchID: self = .touchID
    case .faceID: self = .faceID
    case .opticID: self = .opticID
    default: self = .none
    }
  }
}

extension BiometricsOutcome {
  /// Reads the pair LocalAuthentication answers with. Only the ways of saying "not now" count
  /// as cancellation: everything else, a face simply not recognised included, is a failure.
  init(success: Bool, error: Error?) {
    guard !success else {
      self = .success
      return
    }
    guard let code = (error as? LAError)?.code else {
      self = .failed
      return
    }
    switch code {
    case .userCancel, .systemCancel, .appCancel: self = .cancelled
    default: self = .failed
    }
  }
}
