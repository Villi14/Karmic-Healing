//
// Karmic Healing 2025
//

import SwiftUI

/// Exactly two curves for the whole app. Anything that moves picks one of them;
/// extra animation breaks the tone faster than too little does.
public enum Motion {
  /// Ambient breathing — the aura background and the session ring, nothing else.
  /// Slower than feels right.
  public static let breath: Animation = .easeInOut(duration: 4).repeatForever(autoreverses: true)

  /// One full inhale and exhale of `breath`, in seconds.
  public static let breathPeriod: TimeInterval = 8

  /// How often a breathing view redraws.
  ///
  /// `TimelineView(.animation)` on its own ticks at the display's refresh rate — 120 Hz on
  /// ProMotion — which for a curve this slow means rebuilding the same mesh gradient four times
  /// to move it by nothing anyone can see. A cycle spanning eight seconds is smooth at 30.
  public static let breathTick: TimeInterval = 1.0 / 30.0

  /// Interaction — presses, cards appearing, state changes.
  public static let touch: Animation = .spring(response: 0.35, dampingFraction: 0.75)

  /// A calm fade for the screen-rest overlay. It mirrors the hardware brightness ramp used on iOS.
  public static let screenFade: Animation = .easeInOut(duration: 0.8)

  /// Where the breath is at a given moment, 0 (emptied) to 1 (full).
  ///
  /// Derived from the wall clock rather than from when a view appeared, so every
  /// breathing view is on the same inhale — pages of a `TabView` are built lazily
  /// and would otherwise each start their own cycle.
  public static func breathPhase(at date: Date) -> Double {
    let period = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: breathPeriod)
    return (1 - cos(period / breathPeriod * 2 * .pi)) / 2
  }
}

private struct AuraMotionPausedKey: EnvironmentKey {
  static let defaultValue = false
}

extension EnvironmentValues {
  /// Holds every breathing view in the subtree still.
  ///
  /// Set this whenever the aura is on screen but not being looked at — a resting session covers it
  /// with black yet keeps the display awake, so SwiftUI has no way of knowing the mesh gradient it
  /// is redrawing is hidden. Backgrounding needs no such flag: iOS stops rendering by itself.
  public var auraMotionPaused: Bool {
    get { self[AuraMotionPausedKey.self] }
    set { self[AuraMotionPausedKey.self] = newValue }
  }
}
