//
// Karmic Healing 2025
//

import Foundation

/// Wall-clock schedule behind a self-advancing session.
///
/// A session is defined by *when the current step began*, not by a sleeping task: an in-process
/// countdown drifts whenever the app is throttled, and a step that is one tick late compounds over
/// a whole meditation. Anchoring to `Date` also lets a stalled tick loop catch up in one move.
public struct SessionTimer: Equatable, Sendable {
  /// How long a single step lasts.
  public private(set) var stepDuration: TimeInterval
  /// When the step the user is looking at started running.
  public private(set) var stepStartedAt: Date
  /// A paused session keeps its remaining time frozen.
  public private(set) var isPaused: Bool
  /// What was left of the step at the moment it was paused.
  private var frozenRemaining: TimeInterval

  /// Used whenever settings hold no duration yet.
  public static let defaultDurationMinutes = 5

  public init(minutes: Int, startedAt: Date, isPaused: Bool = false) {
    self.init(stepDuration: Self.duration(fromStoredMinutes: minutes), startedAt: startedAt, isPaused: isPaused)
  }

  public init(stepDuration: TimeInterval, startedAt: Date, isPaused: Bool = false) {
    let duration = max(1, stepDuration)
    self.stepDuration = duration
    self.stepStartedAt = startedAt
    self.isPaused = isPaused
    self.frozenRemaining = duration
  }

  /// Minutes as stored in settings, falling back to the default when unset or nonsensical.
  public static func duration(fromStoredMinutes minutes: Int) -> TimeInterval {
    TimeInterval((minutes > 0 ? minutes : defaultDurationMinutes) * 60)
  }

  public func remaining(at now: Date) -> TimeInterval {
    guard !isPaused else { return frozenRemaining }
    return max(0, stepDuration - now.timeIntervalSince(stepStartedAt))
  }

  /// How far through the current step, 0…1 — for the countdown ring.
  public func progress(at now: Date) -> Double {
    guard stepDuration > 0 else { return 0 }
    return min(1, max(0, 1 - remaining(at: now) / stepDuration))
  }

  /// Restarts the current step. Used whenever the user takes navigation into their own hands, so
  /// they always get a full step to sit with the slide they just chose. Pausing is preserved.
  public mutating func restart(at now: Date) {
    stepStartedAt = now
    frozenRemaining = stepDuration
  }

  public mutating func pause(at now: Date) {
    guard !isPaused else { return }
    frozenRemaining = remaining(at: now)
    isPaused = true
  }

  public mutating func resume(at now: Date) {
    guard isPaused else { return }
    // Re-anchor the start so that exactly the frozen remainder is left to run.
    stepStartedAt = now.addingTimeInterval(frozenRemaining - stepDuration)
    isPaused = false
  }

  /// Applies a new step length and gives the user the full new step from now.
  public mutating func setDuration(_ duration: TimeInterval, at now: Date) {
    stepDuration = max(1, duration)
    restart(at: now)
  }

  /// Whole steps elapsed since the anchor, consuming them from the schedule.
  ///
  /// Returns more than one when the app was suspended for longer than a step: the session then
  /// catches up in a single move instead of silently losing the time.
  public mutating func consumeElapsedSteps(at now: Date) -> Int {
    guard !isPaused, stepDuration > 0 else { return 0 }
    let elapsed = now.timeIntervalSince(stepStartedAt)
    guard elapsed >= stepDuration else { return 0 }
    let completed = Int(elapsed / stepDuration)
    stepStartedAt = stepStartedAt.addingTimeInterval(TimeInterval(completed) * stepDuration)
    return completed
  }
}
