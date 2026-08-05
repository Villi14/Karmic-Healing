//
// Karmic Healing 2025
//

import ComposableArchitecture
import Foundation
import OSLog
import WatchKit

@Reducer
public struct WatchBalancingEnergy {
  @Dependency(\.watchUserDefaults) var userDefaults
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date
  @Dependency(\.audio) var audio
  @Dependency(\.watchRuntime) var runtime

  private enum CancelID { case ticking }

  /// Seconds of stillness before the screen rests, when the user has not chosen otherwise.
  public static let defaultRestDelay = 30

  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents var destination: Destination.State?
    /// The meditation's key, and what its stored progress is filed under.
    public let title: String
    public var currentStep: Int
    public var isCompleted: Bool
    public let steps: [Step]
    /// Wall-clock schedule driving the auto-advance — see `SessionTimer`.
    public var timer: SessionTimer
    /// Latest clock reading, so the view can render a countdown without owning a timer of its own.
    public var now: Date
    /// `onAppear` fires again when a sheet closes; the schedule must survive that.
    public var isRunning: Bool
    /// The screen has gone black to let the user sit with the step.
    public var isResting: Bool
    /// When the screen last lit up — a step change or a touch.
    public var lastWokeAt: Date
    /// Whether the screen rests at all, and after how long.
    public var restEnabled: Bool
    public var restDelay: Int
    /// The session was paused because the app left the screen, not because the user asked — only
    /// such a pause is lifted again on the way back.
    public var pausedByBackground: Bool

    public init(
      title: String,
      currentStep: Int,
      isCompleted: Bool,
      steps: [Step],
      timer: SessionTimer = .init(minutes: 0, startedAt: .distantPast),
      now: Date = .distantPast,
      isRunning: Bool = false,
      isResting: Bool = false,
      lastWokeAt: Date = .distantPast,
      restEnabled: Bool = true,
      restDelay: Int = WatchBalancingEnergy.defaultRestDelay,
      pausedByBackground: Bool = false
    ) {
      self.title = title
      self.currentStep = currentStep
      self.isCompleted = isCompleted
      self.steps = steps
      self.timer = timer
      self.now = now
      self.isRunning = isRunning
      self.isResting = isResting
      self.lastWokeAt = lastWokeAt
      self.restEnabled = restEnabled
      self.restDelay = restDelay
      self.pausedByBackground = pausedByBackground
    }

    public var isLastStep: Bool { currentStep >= steps.count - 1 }
    public var isPaused: Bool { timer.isPaused }
    /// Seconds until the slide flips by itself.
    public var remaining: TimeInterval { timer.remaining(at: now) }
    /// How far through the current step, 0…1.
    public var stepProgress: Double { timer.progress(at: now) }

    /// Brings the screen back and restarts the countdown to the next rest.
    mutating func wake(at now: Date) {
      isResting = false
      lastWokeAt = now
    }

    /// A rest is due only once the screen has been left alone for the chosen delay, and never
    /// while the session is paused — a paused session is one the user is looking at.
    func shouldRest(at now: Date) -> Bool {
      guard restEnabled, !isResting, !isCompleted, !timer.isPaused else { return false }
      return now.timeIntervalSince(lastWokeAt) >= TimeInterval(restDelay)
    }
  }

  public enum Action: Equatable {
    case onAppear
    case onDisappear
    /// The app came back to the wrist — a session paused by leaving picks up where it stood.
    case didBecomeActive
    /// The user left the app. Unlike a dropped wrist, this stops the session where it is.
    case didEnterBackground
    case nextStep
    case previousStep
    case pauseToggled
    /// The user touched the resting screen and wants the step back.
    case screenTapped
    case timerTicked(Date)
    case completeSteps
    case didTapSettings
    case destination(PresentationAction<Destination.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        let now = date.now
        state.now = now
        if !state.isRunning {
          state.timer = SessionTimer(minutes: userDefaults.integer(for: .sessionDuration), startedAt: now)
          state.isRunning = true
          let title = state.title
          let stepDuration = state.timer.stepDuration
          Log.session.debug(
            "Session started — \(title, privacy: .public), step \(stepDuration, privacy: .public)s"
          )
        }
        state.restEnabled = userDefaults.bool(for: .screenRestEnabled, default: true)
        let storedDelay = userDefaults.integer(for: .screenRestDelay)
        state.restDelay = storedDelay > 0 ? storedDelay : Self.defaultRestDelay
        let restEnabled = state.restEnabled
        let restDelay = state.restDelay
        Log.session.debug(
          "Screen rest \(restEnabled ? "on" : "off", privacy: .public) after \(restDelay, privacy: .public)s"
        )
        state.wake(at: now)
        return .merge(
          // Without this the app sleeps the moment the wrist drops, and no step ever lands.
          .run { _ in runtime.start() },
          storeProgress(state),
          ticking()
        )

      case .onDisappear:
        Log.session.debug("Session screen dismissed, tearing the schedule down")
        state.isResting = false
        return .merge(
          .cancel(id: CancelID.ticking),
          .run { _ in runtime.stop() },
          clearStoredProgress()
        )

      case .didBecomeActive:
        let now = date.now
        state.now = now
        // Only a pause this reducer put on is lifted: a session the user paused by hand stays paused.
        if state.pausedByBackground {
          state.timer.resume(at: now)
          state.pausedByBackground = false
        }
        state.wake(at: now)
        return .merge(
          .run { _ in runtime.start() },
          ticking()
        )

      case .didEnterBackground:
        // Leaving the app releases the runtime session, so nothing would carry the steps anyway —
        // the session holds its place rather than running on unwatched.
        let now = date.now
        state.now = now
        state.isResting = false
        if !state.timer.isPaused {
          state.timer.pause(at: now)
          state.pausedByBackground = true
        }
        return .merge(
          .cancel(id: CancelID.ticking),
          .run { _ in runtime.stop() }
        )

      case let .timerTicked(now):
        state.now = now
        guard !state.isCompleted else { return .none }

        let advanced = state.timer.consumeElapsedSteps(at: now)
        guard advanced > 0 else {
          // No step is due, but the screen may have earned its rest.
          guard state.shouldRest(at: now) else { return .none }
          state.isResting = true
          Log.session.debug("Screen resting")
          return .none
        }

        let lastStep = state.steps.count - 1
        let target = state.currentStep + advanced
        guard target <= lastStep else {
          state.currentStep = lastStep
          return .send(.completeSteps)
        }

        Log.session.debug("Advanced \(advanced, privacy: .public) step(s) to \(target, privacy: .public)")
        state.currentStep = target
        // A new step is the moment the screen has to come back — this is the whole point of resting.
        state.wake(at: now)
        return .merge(feedback(), storeProgress(state))

      case .nextStep:
        guard !state.isCompleted else { return .none }
        guard !state.isLastStep else { return .send(.completeSteps) }
        state.currentStep += 1
        // Taking over navigation buys a full step with the slide the user just chose.
        state.timer.restart(at: state.now)
        state.wake(at: state.now)
        return .merge(feedback(), storeProgress(state))

      case .previousStep:
        guard !state.isCompleted, state.currentStep > 0 else { return .none }
        state.currentStep -= 1
        state.timer.restart(at: state.now)
        state.wake(at: state.now)
        return .merge(feedback(), storeProgress(state))

      case .pauseToggled:
        guard !state.isCompleted else { return .none }
        if state.timer.isPaused {
          state.timer.resume(at: state.now)
        } else {
          state.timer.pause(at: state.now)
        }
        state.wake(at: state.now)
        return .none

      case .screenTapped:
        guard state.isResting else {
          // Already awake: touching only buys more time before the next rest.
          state.lastWokeAt = state.now
          return .none
        }
        state.wake(at: state.now)
        return .none

      case .completeSteps:
        guard !state.isCompleted else { return .none }
        state.isCompleted = true
        state.isResting = false
        return .merge(
          .cancel(id: CancelID.ticking),
          .run { _ in runtime.stop() },
          clearStoredProgress()
        )

      case .didTapSettings:
        state.destination = .settings(.withLoadedSettings(userDefaults: userDefaults))
        return .none

      case let .destination(.presented(.settings(.setSessionDuration(minutes)))):
        // Settings talk to the session directly, so the pace changes under the user at once.
        state.timer.setDuration(SessionTimer.duration(fromStoredMinutes: minutes), at: state.now)
        return .none

      case let .destination(.presented(.settings(.toggleScreenRest(enabled)))):
        state.restEnabled = enabled
        state.wake(at: state.now)
        return .none

      case let .destination(.presented(.settings(.setScreenRestDelay(seconds)))):
        state.restDelay = seconds
        state.wake(at: state.now)
        return .none

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }

  // MARK: - Effects

  /// One second of wall clock per tick; `cancelInFlight` guarantees a single live loop per session.
  private func ticking() -> Effect<Action> {
    .run { send in
      while true {
        try await clock.sleep(for: .seconds(1))
        await send(.timerTicked(date.now))
      }
    }
    .cancellable(id: CancelID.ticking, cancelInFlight: true)
  }

  private func storeProgress(_ state: State) -> Effect<Action> {
    let title = state.title
    let step = state.currentStep
    return .run { _ in
      await userDefaults.setAsync(title, for: .activeMeditationTitle)
      await userDefaults.setAsync(step, for: .activeMeditationStep)
      await userDefaults.setAsync(true, for: .hasActiveMeditation)
    }
  }

  private func clearStoredProgress() -> Effect<Action> {
    .run { _ in
      await userDefaults.setAsync(false, for: .hasActiveMeditation)
    }
  }

  private func feedback() -> Effect<Action> {
    .run { _ in
      let soundEnabled = userDefaults.bool(for: .soundEnabled)
      let vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)

      if vibrationEnabled {
        // A notification-style haptic is what a step change should feel like, and it lands at the
        // same moment as the chime rather than half a second behind it.
        await MainActor.run {
          WKInterfaceDevice.current().play(.notification)
        }
      }

      if soundEnabled {
        // An unset volume reads as 0, which used to mean "sound on, but silent".
        let storedVolume = userDefaults.float(for: .audioVolume)
        audio.setVolume(storedVolume > 0 ? storedVolume : 0.5)
        audio.playSound("ding", "wav")
      }
    }
  }
}

@Reducer
public struct Destination {
  @ObservableState
  public enum State: Equatable {
    case settings(WatchSettings.State)
  }

  public enum Action: Equatable {
    case settings(WatchSettings.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
    .ifCaseLet(\.settings, action: \.settings) {
      WatchSettings()
    }
  }
}
