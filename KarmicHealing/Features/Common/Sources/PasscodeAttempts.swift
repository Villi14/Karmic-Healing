//
// Karmic Healing 2026
//

import Foundation

/// How patient the lock screen is with wrong codes.
///
/// Four digits are ten thousand codes, which a person with the phone in hand could work through
/// given an unlimited number of tries. A few free attempts cover the ordinary case of mistyping;
/// past that each further wrong code costs a wait, and the waits grow.
public struct PasscodeAttempts: Equatable, Sendable {
  /// Wrong codes allowed before the waiting starts.
  public static let allowance = 5

  /// What the first, second, and every later wrong code past the allowance costs, in seconds.
  static let penalties: [TimeInterval] = [30, 60, 300]

  public private(set) var failures = 0
  public private(set) var openAt: Date?

  public init() {}

  /// The wait still to go, in whole seconds — zero whenever a code may be tried.
  public func remainingWait(at now: Date) -> Int {
    guard let openAt, openAt > now else { return 0 }
    return Int((openAt.timeIntervalSince(now)).rounded(.up))
  }

  public func isWaiting(at now: Date) -> Bool {
    remainingWait(at: now) > 0
  }

  public mutating func recordFailure(at now: Date) {
    failures += 1

    let beyondAllowance = failures - Self.allowance
    guard beyondAllowance > 0 else { return }

    let penalty = Self.penalties[min(beyondAllowance, Self.penalties.count) - 1]
    openAt = now.addingTimeInterval(penalty)
  }

  /// The right code wipes the slate: the next mistyped one starts from the full allowance again.
  public mutating func recordSuccess() {
    self = .init()
  }
}
