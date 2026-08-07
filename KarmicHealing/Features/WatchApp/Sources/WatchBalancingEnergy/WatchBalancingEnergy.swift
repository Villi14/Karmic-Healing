//
// Karmic Healing 2025
//

import ComposableArchitecture
import Foundation
import OSLog
import SwiftUI

@Reducer
public struct WatchBalancingEnergy {
  @Dependency(\.watchUserDefaults) var userDefaults
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date) var date
  @Dependency(\.audio) var audio
  @Dependency(\.watchRuntime) var runtime

  private enum CancelID { case ticking }

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
      pausedByBackground: Bool = false
    ) {
      self.title = title
      self.currentStep = currentStep
      self.isCompleted = isCompleted
      self.steps = steps
      self.timer = timer
      self.now = now
      self.isRunning = isRunning
      self.pausedByBackground = pausedByBackground
    }

    public var isLastStep: Bool { currentStep >= steps.count - 1 }
    public var isPaused: Bool { timer.isPaused }
    /// Seconds until the slide flips by itself.
    public var remaining: TimeInterval { timer.remaining(at: now) }
    /// How far through the current step, 0…1.
    public var stepProgress: Double { timer.progress(at: now) }
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
        return .merge(
          // Without this the app sleeps the moment the wrist drops, and no step ever lands.
          .run { _ in runtime.start() },
          storeProgress(state),
          ticking()
        )

      case .onDisappear:
        Log.session.debug("Session screen dismissed, tearing the schedule down")
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
        return .merge(
          .run { _ in runtime.start() },
          ticking()
        )

      case .didEnterBackground:
        // Leaving the app releases the runtime session, so nothing would carry the steps anyway —
        // the session holds its place rather than running on unwatched.
        let now = date.now
        state.now = now
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
        guard advanced > 0 else { return .none }

        let lastStep = state.steps.count - 1
        let target = state.currentStep + advanced
        guard target <= lastStep else {
          state.currentStep = lastStep
          return .send(.completeSteps)
        }

        Log.session.debug("Advanced \(advanced, privacy: .public) step(s) to \(target, privacy: .public)")
        state.currentStep = target
        return .merge(feedback(), storeProgress(state))

      case .nextStep:
        guard !state.isCompleted else { return .none }
        guard !state.isLastStep else { return .send(.completeSteps) }
        state.currentStep += 1
        // Taking over navigation buys a full step with the slide the user just chose.
        state.timer.restart(at: state.now)
        return .merge(feedback(), storeProgress(state))

      case .previousStep:
        guard !state.isCompleted, state.currentStep > 0 else { return .none }
        state.currentStep -= 1
        state.timer.restart(at: state.now)
        return .merge(feedback(), storeProgress(state))

      case .pauseToggled:
        guard !state.isCompleted else { return .none }
        if state.timer.isPaused {
          state.timer.resume(at: state.now)
        } else {
          state.timer.pause(at: state.now)
        }
        return .none

      case .completeSteps:
        guard !state.isCompleted else { return .none }
        state.isCompleted = true
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

  /// How a new step reaches the user.
  ///
  /// The haptic is not optional and has no setting behind it: the watch cannot light its own
  /// display, so with the wrist down a buzz is the only thing left that can say a step has turned.
  /// Sound is a choice on top of it.
  private func feedback() -> Effect<Action> {
    .run { _ in
      runtime.notify()

      if userDefaults.bool(for: .soundEnabled) {
        // An unset volume reads as 0, which used to mean "sound on, but silent".
        let storedVolume = userDefaults.float(for: .audioVolume)
        audio.setVolume(storedVolume > 0 ? storedVolume : 0.5)
        audio.playSound("ding", "wav")
      }
    }
  }
}

// MARK: - Scene phase

extension WatchBalancingEnergy.Action {
  /// What a change of scene phase means to a session, if anything.
  ///
  /// A dropped wrist reads as `.inactive`, and the runtime session is carrying the meditation
  /// through it — so it must not stop anything. Only `.background`, the user leaving the app, does.
  public static func forScenePhase(_ phase: ScenePhase) -> WatchBalancingEnergy.Action? {
    switch phase {
    case .active: .didBecomeActive
    case .background: .didEnterBackground
    default: nil
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
