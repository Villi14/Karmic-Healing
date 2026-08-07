//
// Karmic Healing 2025
//

import Dependencies
import Foundation
import OSLog
import WatchKit

extension DependencyValues {
  public var watchRuntime: WatchRuntimeClient {
    get { self[WatchRuntimeClient.self] }
    set { self[WatchRuntimeClient.self] = newValue }
  }
}

/// Keeps the watch app alive for the length of a session.
///
/// Without this the app is suspended as soon as the wrist drops — which is exactly the posture a
/// meditation is done in — and neither the chime nor the haptic for a step ever fires. The session
/// type comes from `WKBackgroundModes` in the Info.plist (`mindfulness`), and lasts up to an hour.
public struct WatchRuntimeClient {
  public var start: @Sendable () -> Void
  public var stop: @Sendable () -> Void
  /// Buzzes the wrist for a step, through the session so it lands with the arm down.
  public var notify: @Sendable () -> Void

  public init(
    start: @escaping @Sendable () -> Void,
    stop: @escaping @Sendable () -> Void,
    notify: @escaping @Sendable () -> Void
  ) {
    self.start = start
    self.stop = stop
    self.notify = notify
  }
}

extension WatchRuntimeClient: DependencyKey {
  public static let liveValue: Self = {
    let holder = RuntimeSessionHolder()
    return Self(
      start: { holder.start() },
      stop: { holder.stop() },
      notify: { holder.notify() }
    )
  }()

  public static let testValue: Self = Self(
    start: { },
    stop: { },
    notify: { }
  )
}

/// Owns the one runtime session the app may have, and outlives every screen that asks for it.
///
/// The session is only ever released once WatchKit says it is invalid. Letting go of it any earlier
/// — while it is still starting up, or right after asking it to stop — deallocates an object the
/// system still has registered, which it reports as "WKExtendedRuntimeObject was dealloced while
/// running" and then fails to end.
private final class RuntimeSessionHolder: NSObject, WKExtendedRuntimeSessionDelegate, @unchecked Sendable {
  private var session: WKExtendedRuntimeSession?
  /// A stop asked for before the session finished starting; `invalidate()` does nothing that early.
  private var stopWhenStarted = false

  func start() {
    Task { @MainActor in
      self.stopWhenStarted = false
      // Starting a second session while one is live throws; one per meditation is what we want.
      // `start()` returns long before the state turns `.running`, yet the session is registered
      // with the system from the moment it is handed over — so anything short of `.invalid` is
      // still ours to keep.
      if let state = self.session?.state, state != .invalid { return }
      let session = WKExtendedRuntimeSession()
      session.delegate = self
      self.session = session
      session.start()
    }
  }

  func stop() {
    Task { @MainActor in
      guard let session = self.session else { return }
      switch session.state {
      case .running, .scheduled:
        // The reference is kept until `didInvalidateWith` confirms the system is done with it.
        session.invalidate()
      case .invalid:
        self.session = nil
      default:
        // Still starting up: nothing to invalidate yet, so the stop waits for the start callback.
        self.stopWhenStarted = true
      }
    }
  }

  /// Buzzes the wrist for a step.
  ///
  /// `WKInterfaceDevice.play(_:)` is only honoured while the app is frontmost, which a wrist lying
  /// by the user's side is not — so a step announced that way went unfelt in exactly the posture a
  /// meditation is done in. A running session has its own way of reaching the user, and that is
  /// what this asks; the device is the fallback for the moments before the session is up.
  func notify() {
    Task { @MainActor in
      if let session = self.session, session.state == .running {
        session.notifyUser(hapticType: .notification)
      } else {
        Log.session.notice("No running session to notify through, buzzing the device directly")
        WKInterfaceDevice.current().play(.notification)
      }
    }
  }

  func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    Log.session.debug("Extended runtime session started")
    guard stopWhenStarted, session === extendedRuntimeSession else { return }
    stopWhenStarted = false
    Log.session.debug("Stop arrived before the session was up, ending it now")
    extendedRuntimeSession.invalidate()
  }

  func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
    // Nothing carries the session past this point: it holds until the user is back with it.
    Log.session.notice("Extended runtime session about to expire")
  }

  func extendedRuntimeSession(
    _ extendedRuntimeSession: WKExtendedRuntimeSession,
    didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
    error: Error?
  ) {
    Log.session.debug("Extended runtime session invalidated, reason: \(reason.rawValue, privacy: .public)")
    // A late callback from a previous session must not release the one running now.
    if session === extendedRuntimeSession {
      session = nil
      stopWhenStarted = false
    }
  }
}
