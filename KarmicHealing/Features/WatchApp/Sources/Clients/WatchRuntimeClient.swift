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

  public init(
    start: @escaping @Sendable () -> Void,
    stop: @escaping @Sendable () -> Void
  ) {
    self.start = start
    self.stop = stop
  }
}

extension WatchRuntimeClient: DependencyKey {
  public static let liveValue: Self = {
    let holder = RuntimeSessionHolder()
    return Self(
      start: { holder.start() },
      stop: { holder.stop() }
    )
  }()

  public static let testValue: Self = Self(
    start: { },
    stop: { }
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
