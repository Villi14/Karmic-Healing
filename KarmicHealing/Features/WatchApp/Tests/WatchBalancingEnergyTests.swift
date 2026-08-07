//
// Karmic Healing 2025
//

import ComposableArchitecture
import ConcurrencyExtras
import Foundation
import SwiftUI
import XCTest
@testable import KarmicHealingWatch

@MainActor
final class WatchBalancingEnergyTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_000_000)

  private func makeState(
    currentStep: Int = 0,
    steps: [Step] = Step.part2
  ) -> WatchBalancingEnergy.State {
    .init(title: "essential_self", currentStep: currentStep, isCompleted: false, steps: steps)
  }

  /// What `WatchSettings.State.withLoadedSettings` produces from the test UserDefaults client.
  private static func loadedSettings(sessionDuration: Int = 5) -> WatchSettings.State {
    .init(
      soundEnabled: false,
      audioVolume: 1.0,
      sessionDuration: sessionDuration,
      userLanguage: "en"
    )
  }

  /// A session already running at `start`, with a five-minute step.
  private func makeRunningState(
    currentStep: Int = 0,
    steps: [Step] = Step.part2
  ) -> WatchBalancingEnergy.State {
    .init(
      title: "essential_self",
      currentStep: currentStep,
      isCompleted: false,
      steps: steps,
      timer: SessionTimer(minutes: 5, startedAt: start),
      now: start,
      isRunning: true
    )
  }

  func testNextStepAdvancesAndRestartsTheStepsClock() async {
    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    }

    await store.send(.nextStep) {
      $0.currentStep = 1
      $0.timer.restart(at: self.start)
    }
    await store.finish()
  }

  func testNextStepOnLastStepCompletesTheFlow() async {
    let steps = Step.part2
    let store = TestStore(initialState: makeRunningState(currentStep: steps.count - 1, steps: steps)) {
      WatchBalancingEnergy()
    }

    await store.send(.nextStep)
    await store.receive(.completeSteps) { $0.isCompleted = true }
    await store.finish()
  }

  func testPreviousStepOnFirstStepIsIgnored() async {
    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    }

    await store.send(.previousStep)
    XCTAssertEqual(store.state.currentStep, 0)
    await store.finish()
  }

  func testPreviousStepMovesBackAndRestartsTheStepsClock() async {
    let store = TestStore(initialState: makeRunningState(currentStep: 2)) {
      WatchBalancingEnergy()
    }

    await store.send(.previousStep) {
      $0.currentStep = 1
      $0.timer.restart(at: self.start)
    }
    await store.finish()
  }

  func testOnAppearReadsTheStoredDurationAndHoldsAnExtendedRuntimeSession() async {
    let clock = TestClock()
    let runtimeStarts = LockIsolated(0)
    let runtimeStops = LockIsolated(0)

    let store = TestStore(initialState: makeState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(start)
      // The watch used to ignore this and always run a five-minute step.
      $0.watchUserDefaults.integerForKey = { _ in 1 }
      $0.watchRuntime.start = { runtimeStarts.withValue { $0 += 1 } }
      $0.watchRuntime.stop = { runtimeStops.withValue { $0 += 1 } }
    }

    await store.send(.onAppear) {
      $0.now = self.start
      $0.timer = SessionTimer(minutes: 1, startedAt: self.start)
      $0.isRunning = true
      // The same stub backs every integer key, so the rest delay reads 1 too.
    }
    await store.send(.onDisappear)
    await store.finish()

    // The runtime session, not a notification, is what carries the steps on the wrist.
    XCTAssertEqual(runtimeStarts.value, 1)
    XCTAssertEqual(runtimeStops.value, 1)
  }

  func testOnAppearStartsTheTimerThatAdvancesTheSlides() async {
    let clock = TestClock()
    let now = LockIsolated(start)

    let store = TestStore(initialState: makeState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
      $0.watchUserDefaults.integerForKey = { _ in 5 }
    }

    await store.send(.onAppear) {
      $0.now = self.start
      $0.timer = SessionTimer(minutes: 5, startedAt: self.start)
      $0.isRunning = true
    }

    let due = start.addingTimeInterval(300)
    now.setValue(due)
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked(due)) {
      $0.now = due
      _ = $0.timer.consumeElapsedSteps(at: due)
      $0.currentStep = 1
    }

    await store.send(.onDisappear)
    await store.finish()
  }

  func testOnAppearKeepsAnAlreadyRunningSessionTimer() async {
    var state = makeRunningState(currentStep: 2)
    state.timer = SessionTimer(minutes: 5, startedAt: start.addingTimeInterval(-120))
    state.now = start.addingTimeInterval(-120)
    let clock = TestClock()

    let store = TestStore(initialState: state) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .constant(self.start)
    }

    await store.send(.onAppear) {
      $0.now = self.start
    }
    XCTAssertEqual(store.state.currentStep, 2)
    XCTAssertTrue(store.state.isRunning)
    XCTAssertEqual(store.state.timer.remaining(at: self.start), 180)

    await store.send(.onDisappear)
    await store.finish()
  }

  func testTimeWithTheWristDownIsCaughtUpInOneStep() async {
    let clock = TestClock()
    let now = LockIsolated(start)

    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
    }

    let back = start.addingTimeInterval(22 * 60)
    now.setValue(back)
    await store.send(.timerTicked(back)) {
      $0.now = back
      _ = $0.timer.consumeElapsedSteps(at: back)
      $0.currentStep = 4
    }
    await store.finish()
  }

  func testTimerTickPastTheFinalStepCompletesTheFlow() async {
    let steps = [Step.step1, Step.step2]
    let store = TestStore(initialState: makeRunningState(steps: steps)) {
      WatchBalancingEnergy()
    }

    let due = start.addingTimeInterval(600)
    await store.send(.timerTicked(due)) {
      $0.now = due
      _ = $0.timer.consumeElapsedSteps(at: due)
      $0.currentStep = steps.count - 1
    }
    await store.receive(.completeSteps) { $0.isCompleted = true }
    await store.finish()
  }

  func testCompleteStepsReleasesTheRuntimeSession() async {
    let runtimeStops = LockIsolated(0)

    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.watchRuntime.stop = { runtimeStops.withValue { $0 += 1 } }
    }

    await store.send(.completeSteps) { $0.isCompleted = true }
    await store.finish()

    XCTAssertEqual(runtimeStops.value, 1)
  }

  /// The complaint this whole design answers: a closed app kept buzzing its way through the session.
  func testClosingTheAppStopsTheSessionWhereItStands() async {
    let clock = TestClock()
    let now = LockIsolated(start)
    let runtimeStops = LockIsolated(0)

    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
      $0.watchRuntime.stop = { runtimeStops.withValue { $0 += 1 } }
    }

    await store.send(.didEnterBackground) {
      $0.timer.pause(at: self.start)
      $0.pausedByBackground = true
    }

    // The ticking loop is gone and nothing is queued, so an hour away moves the session nowhere.
    let back = start.addingTimeInterval(3_600)
    now.setValue(back)
    await clock.advance(by: .seconds(3_600))
    XCTAssertEqual(store.state.currentStep, 0)

    await store.send(.didBecomeActive) {
      $0.now = back
      $0.timer.resume(at: back)
      $0.pausedByBackground = false
    }
    XCTAssertEqual(store.state.remaining, 300, "the step the user left on still has its full length")

    await store.send(.onDisappear)
    await store.finish()

    XCTAssertEqual(runtimeStops.value, 2, "leaving the app releases the runtime session, as does leaving the screen")
  }

  func testAPauseTheUserAskedForSurvivesTheTripToTheBackground() async {
    let clock = TestClock()
    let now = LockIsolated(start)

    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
    }

    await store.send(.pauseToggled) { $0.timer.pause(at: self.start) }
    // Already paused, so backgrounding takes no pause of its own — and must not lift the user's.
    await store.send(.didEnterBackground)

    let back = start.addingTimeInterval(60)
    now.setValue(back)
    await store.send(.didBecomeActive) { $0.now = back }

    XCTAssertTrue(store.state.isPaused, "coming back must not start a session the user stopped")

    await store.send(.onDisappear)
    await store.finish()
  }

  func testPausingFreezesTheSession() async {
    let now = LockIsolated(start)

    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.date = .init { now.value }
    }

    await store.send(.pauseToggled) { $0.timer.pause(at: self.start) }

    let later = start.addingTimeInterval(3_600)
    now.setValue(later)
    await store.send(.timerTicked(later)) { $0.now = later }
    XCTAssertEqual(store.state.currentStep, 0)

    await store.finish()
  }

  func testPauseToggleResumesFromTheFrozenRemainder() async {
    var state = makeRunningState()
    state.now = start.addingTimeInterval(120)

    let store = TestStore(initialState: state) {
      WatchBalancingEnergy()
    }

    await store.send(.pauseToggled) { $0.timer.pause(at: self.start.addingTimeInterval(120)) }
    await store.send(.pauseToggled) { $0.timer.resume(at: self.start.addingTimeInterval(120)) }

    XCTAssertEqual(store.state.remaining, 180)
    await store.finish()
  }

  func testStepProgressIsPersistedSoTheListCanOfferToResume() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: makeRunningState(currentStep: 2)) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.watchUserDefaults.setString = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.watchUserDefaults.setInteger = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.watchUserDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
    }

    await store.send(.nextStep) {
      $0.currentStep = 3
      $0.timer.restart(at: self.start)
    }
    await store.finish()

    XCTAssertEqual(
      writes.value,
      [
        "active_meditation_title=essential_self",
        "active_meditation_step=3",
        "has_active_meditation=true"
      ]
    )
  }

  func testDidTapSettingsPresentsSettings() async {
    let store = TestStore(initialState: makeState()) {
      WatchBalancingEnergy()
    }

    await store.send(.didTapSettings) {
      $0.destination = .settings(Self.loadedSettings())
    }
    await store.finish()
  }

  func testChangingTheDurationInSettingsAppliesToTheRunningSession() async {
    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    }

    await store.send(.didTapSettings) { $0.destination = .settings(Self.loadedSettings()) }
    await store.send(.destination(.presented(.settings(.setSessionDuration(1))))) {
      $0.destination = .settings(Self.loadedSettings(sessionDuration: 1))
      $0.timer.setDuration(60, at: self.start)
    }
    await store.finish()

    XCTAssertEqual(store.state.remaining, 60, "the new pace takes hold under the user at once")
  }

  // MARK: - Feedback

  /// With the arm down the watch can neither light its display nor be looked at, so the buzz is
  /// the only thing left that can announce a step — and it answers to no setting.
  func testEveryStepBuzzesTheWristEvenWithSoundOff() async {
    let buzzes = LockIsolated(0)
    let played = LockIsolated<[String]>([])

    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.watchRuntime.notify = { buzzes.withValue { $0 += 1 } }
      $0.watchUserDefaults.boolForKey = { _ in false }
      $0.audio.playSound = { name, ext in played.withValue { $0.append("\(name).\(ext)") } }
    }

    await store.send(.nextStep) {
      $0.currentStep = 1
      $0.timer.restart(at: self.start)
    }
    await store.finish()

    XCTAssertEqual(buzzes.value, 1)
    XCTAssertEqual(played.value, [], "sound is still the user's to turn off")
  }

  func testASoundJoinsTheBuzzWhenTheUserAsksForOne() async {
    let buzzes = LockIsolated(0)
    let played = LockIsolated<[String]>([])

    let store = TestStore(initialState: makeRunningState()) {
      WatchBalancingEnergy()
    } withDependencies: {
      $0.watchRuntime.notify = { buzzes.withValue { $0 += 1 } }
      $0.watchUserDefaults.boolForKey = { _ in true }
      $0.audio.playSound = { name, ext in played.withValue { $0.append("\(name).\(ext)") } }
    }

    // A step falling due on its own is the case that matters: the user is not holding the watch.
    let due = start.addingTimeInterval(300)
    await store.send(.timerTicked(due)) {
      $0.now = due
      _ = $0.timer.consumeElapsedSteps(at: due)
      $0.currentStep = 1
    }
    await store.finish()

    XCTAssertEqual(buzzes.value, 1)
    XCTAssertEqual(played.value, ["ding.wav"])
  }

  // MARK: - Scene phase

  /// The posture a meditation is done in: the wrist drops, the app goes inactive, and the runtime
  /// session carries the steps on regardless.
  func testADroppedWristIsNotADeparture() {
    XCTAssertNil(WatchBalancingEnergy.Action.forScenePhase(.inactive))
  }

  func testLeavingTheAppStopsTheSessionAndReturningResumesIt() {
    XCTAssertEqual(WatchBalancingEnergy.Action.forScenePhase(.background), .didEnterBackground)
    XCTAssertEqual(WatchBalancingEnergy.Action.forScenePhase(.active), .didBecomeActive)
  }
}
