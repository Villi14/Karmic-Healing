//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import OSLog
import UIKit

extension DependencyValues {
  public var screen: ScreenClient {
    get { self[ScreenClient.self] }
    set { self[ScreenClient.self] = newValue }
  }
}

/// Lets a session darken the display without letting the device fall asleep.
///
/// iOS has no API to switch the display off and back on, and letting it sleep is exactly what we
/// must avoid: the app is suspended seconds later and can no longer chime on its own. Holding the
/// device awake and taking the brightness to zero gives the same restful darkness while the session
/// keeps running — which is what makes notifications a fallback rather than the engine.
public struct ScreenClient {
  /// Holds the device awake and remembers the brightness to come back to.
  public var beginSession: @Sendable () -> Void
  /// Restores brightness and hands sleep control back to the system.
  public var endSession: @Sendable () -> Void
  public var setDimmed: @Sendable (Bool) -> Void
  /// Puts brightness back after a crash or a kill that skipped `endSession`.
  public var restoreAfterUncleanExit: @Sendable () -> Void

  public init(
    beginSession: @escaping @Sendable () -> Void,
    endSession: @escaping @Sendable () -> Void,
    setDimmed: @escaping @Sendable (Bool) -> Void,
    restoreAfterUncleanExit: @escaping @Sendable () -> Void
  ) {
    self.beginSession = beginSession
    self.endSession = endSession
    self.setDimmed = setDimmed
    self.restoreAfterUncleanExit = restoreAfterUncleanExit
  }
}

extension ScreenClient: DependencyKey {
  public static let liveValue: Self = {
    let controller = ScreenController()
    return Self(
      beginSession: { controller.run { $0.beginSession() } },
      endSession: { controller.run { $0.endSession() } },
      setDimmed: { dimmed in controller.run { $0.setDimmed(dimmed) } },
      restoreAfterUncleanExit: { controller.run { $0.restoreAfterUncleanExit() } }
    )
  }()

  public static let testValue: Self = Self(
    beginSession: { },
    endSession: { },
    setDimmed: { _ in },
    restoreAfterUncleanExit: { }
  )
}

private final class ScreenController: Sendable {
  /// The client's calls are synchronous and the screen is main-actor only, so every one hops.
  func run(_ work: @escaping @MainActor (ScreenState) -> Void) {
    Task { @MainActor in work(ScreenState.shared) }
  }
}

@MainActor
private final class ScreenState {
  static let shared = ScreenState()

  private var brightnessToRestore: CGFloat?
  private var transitionTask: Task<Void, Never>?

  private static let brightnessFadeSteps = 24
  private static let brightnessFadeInterval = Duration.milliseconds(33)

  /// What the session last asked for, kept so a `setDimmed` that arrives before `beginSession` is
  /// applied rather than dropped — the two hop to the main actor as separate tasks and are not
  /// ordered against each other.
  private var wantsDim = false

  /// The screen the user is actually looking at.
  ///
  /// `connectedScenes` is an unordered set that can also hold background or external-display
  /// scenes, and brightness written to one of those does nothing at all.
  private var screen: UIScreen? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let active = scenes.first { $0.activationState == .foregroundActive }
      ?? scenes.first { $0.activationState == .foregroundInactive }
    return (active ?? scenes.first)?.screen
  }

  func beginSession() {
    UIApplication.shared.isIdleTimerDisabled = true
    guard let screen else { return }

    if brightnessToRestore == nil {
      // Software dimming reaches below the hardware floor, so "resting" really is black.
      screen.wantsSoftwareDimming = true
      brightnessToRestore = screen.brightness
      // Brightness is a *system* setting that outlives the app, so the value to come back to is
      // persisted: a crash mid-session must not leave the user with a black phone.
      UserDefaults.standard.set(Float(screen.brightness), forKey: UserDefaultsClient.Keys.brightnessBeforeSession)
    }

    screen.wantsSoftwareDimming = true
    // A rest that was asked for while the session was starting still has to land.
    apply()
  }

  func setDimmed(_ dimmed: Bool) {
    wantsDim = dimmed
    apply()
  }

  private func apply() {
    guard let screen, let brightnessToRestore else {
      Log.session.notice("Screen dim ignored — no session brightness captured yet")
      return
    }
    let target: CGFloat = wantsDim ? 0 : brightnessToRestore
    transitionTask?.cancel()
    transitionTask = Task { @MainActor [weak self] in
      guard let self, await self.animateBrightness(to: target) else { return }
      self.transitionTask = nil
      Log.session.debug(
        "Screen brightness set to \(Double(target), privacy: .public), now \(Double(screen.brightness), privacy: .public)"
      )
    }
  }

  func endSession() {
    wantsDim = false
    transitionTask?.cancel()

    guard brightnessToRestore != nil, screen != nil else {
      finishSession()
      return
    }

    // Let the screen come back gently as well. Keep the original brightness until the animation
    // completes so a second beginSession can still reuse it if the app returns immediately.
    transitionTask = Task { @MainActor [weak self] in
      guard let self, await self.animateBrightness(to: self.brightnessToRestore ?? 1) else { return }
      guard let screen = self.screen else {
        self.finishSession()
        self.transitionTask = nil
        return
      }
      screen.wantsSoftwareDimming = false
      self.finishSession()
      self.transitionTask = nil
    }
  }

  private func animateBrightness(to target: CGFloat) async -> Bool {
    guard let screen else { return false }
    let start = screen.brightness
    guard abs(start - target) > 0.001 else {
      screen.brightness = target
      return true
    }

    for step in 1...Self.brightnessFadeSteps {
      do {
        try await Task.sleep(for: Self.brightnessFadeInterval)
      } catch {
        return false
      }
      guard !Task.isCancelled else { return false }

      let linearProgress = CGFloat(step) / CGFloat(Self.brightnessFadeSteps)
      // Smoothstep avoids an abrupt start or stop at either end of the fade.
      let progress = linearProgress * linearProgress * (3 - 2 * linearProgress)
      screen.brightness = start + (target - start) * progress
    }

    return true
  }

  private func finishSession() {
    brightnessToRestore = nil
    UserDefaults.standard.removeObject(forKey: UserDefaultsClient.Keys.brightnessBeforeSession)
    UIApplication.shared.isIdleTimerDisabled = false
  }

  func restoreAfterUncleanExit() {
    guard
      UserDefaults.standard.object(forKey: UserDefaultsClient.Keys.brightnessBeforeSession) != nil,
      let screen
    else { return }
    let saved = CGFloat(UserDefaults.standard.float(forKey: UserDefaultsClient.Keys.brightnessBeforeSession))
    Log.session.notice("Restoring brightness left behind by an unclean exit")
    transitionTask?.cancel()
    screen.brightness = saved
    screen.wantsSoftwareDimming = false
    UserDefaults.standard.removeObject(forKey: UserDefaultsClient.Keys.brightnessBeforeSession)
  }
}
