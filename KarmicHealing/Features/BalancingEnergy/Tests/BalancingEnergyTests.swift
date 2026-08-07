//
// Karmic Healing 2025
//

import Common
import ComposableArchitecture
import ConcurrencyExtras
import Foundation
import SwiftUI
import XCTest
@testable import BalancingEnergy

@MainActor
final class BalancingEnergyTests: XCTestCase {
  private let start = Date(timeIntervalSince1970: 1_000_000)

  private func makeState(
    kind: BalancingEnergy.SessionKind = .essentialSelf,
    title: String = "essential_self",
    currentStep: Int = 0,
    steps: [Step] = Step.part2
  ) -> BalancingEnergy.State {
    .init(kind: kind, title: title, currentStep: currentStep, isCompleted: false, steps: steps)
  }

  /// A session already running at `start`, with a five-minute step.
  ///
  /// Screen rest is off by default here so the timer tests read plainly; the rest tests turn it on.
  private func makeRunningState(
    kind: BalancingEnergy.SessionKind = .essentialSelf,
    currentStep: Int = 0,
    steps: [Step] = Step.part2,
    restEnabled: Bool = false,
    restDelay: Int = 30
  ) -> BalancingEnergy.State {
    .init(
      kind: kind,
      title: "essential_self",
      currentStep: currentStep,
      isCompleted: false,
      steps: steps,
      timer: SessionTimer(minutes: 5, startedAt: start),
      now: start,
      isRunning: true,
      lastWokeAt: start,
      restEnabled: restEnabled,
      restDelay: restDelay
    )
  }

  func testNextStepAdvancesAndRestartsTheStepsClock() async {
    let store = TestStore(initialState: makeRunningState()) {
      BalancingEnergy()
    }

    await store.send(.nextStep) {
      $0.currentStep = 1
      $0.timer.restart(at: self.start)
    }
    await store.send(.nextStep) {
      $0.currentStep = 2
      $0.timer.restart(at: self.start)
    }
    await store.finish()
  }

  func testNextStepOnLastStepCompletesTheFlow() async {
    let steps = Step.part2
    let dismissals = LockIsolated(0)
    let store = TestStore(initialState: makeRunningState(currentStep: steps.count - 1, steps: steps)) {
      BalancingEnergy()
    } withDependencies: {
      $0.dismiss = DismissEffect { dismissals.withValue { $0 += 1 } }
    }

    await store.send(.nextStep)
    await store.receive(.completeSteps) { $0.isCompleted = true }
    await store.receive(.markInitialProcessCompletedIfNeeded)
    await store.finish()

    // A finished session leaves on its own — the button no longer pops the screen out from
    // under the actions that follow completion.
    XCTAssertEqual(dismissals.value, 1)
  }

  func testPreviousStepGoesBackAndStopsAtTheFirstStep() async {
    let store = TestStore(initialState: makeRunningState(currentStep: 1)) {
      BalancingEnergy()
    }

    await store.send(.previousStep) {
      $0.currentStep = 0
      $0.timer.restart(at: self.start)
    }
    await store.send(.previousStep)
    await store.finish()
  }

  func testCompletingTwiceIsIgnored() async {
    var state = makeRunningState()
    state.isCompleted = true
    let store = TestStore(initialState: state) {
      BalancingEnergy()
    }

    // A late swipe or tick must not restart anything — or send the finished session out a
    // second time — after it is over.
    await store.send(.completeSteps)
    await store.send(.nextStep)
    await store.finish()
  }

  func testCompletingTheInitialProcessPersistsTheFlagBeforeLeaving() async {
    let writes = LockIsolated<[String]>([])
    let order = LockIsolated<[String]>([])

    // The title is deliberately unrelated: persistence must key off `kind`, not the localized title.
    let state = makeRunningState(kind: .initialProcess, steps: Step.part1)
    let store = TestStore(initialState: state) {
      BalancingEnergy()
    } withDependencies: {
      $0.userDefaults.setBool = { value, key in
        writes.withValue { $0.append("\(key)=\(value)") }
        order.withValue { $0.append("\(key)=\(value)") }
      }
      $0.dismiss = DismissEffect { order.withValue { $0.append("dismiss") } }
    }

    await store.send(.completeSteps) { $0.isCompleted = true }
    await store.receive(.markInitialProcessCompletedIfNeeded)
    await store.receive(.initialProcessCompletionSaved)
    await store.finish()

    // The flag, and the action that tells the list about it, both land before the screen goes:
    // dismissing first left them to arrive at a stack element that no longer existed.
    XCTAssertEqual(writes.value, ["initial_process_completed=true"])
    XCTAssertEqual(order.value, ["initial_process_completed=true", "dismiss"])
  }

  func testCompletingAnotherFlowDoesNotPersistTheInitialProcessFlag() async {
    let writes = LockIsolated<[String]>([])

    let store = TestStore(initialState: makeRunningState(kind: .divineSelf, steps: Step.part3)) {
      BalancingEnergy()
    } withDependencies: {
      $0.userDefaults.setBool = { value, key in writes.withValue { $0.append("\(key)=\(value)") } }
      $0.dismiss = DismissEffect { }
    }

    await store.send(.completeSteps) { $0.isCompleted = true }
    await store.receive(.markInitialProcessCompletedIfNeeded)
    await store.finish()

    XCTAssertTrue(writes.value.isEmpty)
  }

  func testDidTapSettingsPresentsSettings() async {
    let store = TestStore(initialState: makeState()) {
      BalancingEnergy()
    }

    await store.send(.didTapSettings) {
      $0.destination = .settings(.init())
    }
    await store.finish()
  }

  func testChangingTheDurationInSettingsAppliesToTheRunningSession() async {
    let store = TestStore(initialState: makeRunningState()) {
      BalancingEnergy()
    }

    await store.send(.didTapSettings) { $0.destination = .settings(.init()) }
    await store.send(.destination(.presented(.settings(.sessionDurationChanged(1))))) {
      $0.destination = .settings(.init(sessionDuration: 1))
      $0.timer.setDuration(60, at: self.start)
    }
    await store.finish()

    XCTAssertEqual(store.state.remaining, 60, "the new pace takes hold under the user at once")
  }

  func testOnAppearReadsTheStoredDurationAndAdvancesOnItsOwn() async {
    let clock = TestClock()
    let now = LockIsolated(start)

    let store = TestStore(initialState: makeState()) {
      BalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
      $0.userDefaults.integerForKey = { _ in 5 }
    }

    await store.send(.onAppear) {
      $0.now = self.start
      $0.timer = SessionTimer(minutes: 5, startedAt: self.start)
      $0.isRunning = true
      $0.lastWokeAt = self.start
      $0.restDelay = 5
    }

    let due = start.addingTimeInterval(300)
    now.setValue(due)
    await clock.advance(by: .seconds(1))
    await store.receive(.timerTicked(due)) {
      $0.now = due
      _ = $0.timer.consumeElapsedSteps(at: due)
      $0.currentStep = 1
      $0.lastWokeAt = due
    }

    await store.send(.onDisappear)
    await store.finish()
  }

  func testBackgroundingHoldsTheSessionWhereItStands() async {
    let clock = TestClock()
    let now = LockIsolated(start)

    let store = TestStore(initialState: makeRunningState()) {
      BalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
    }

    await store.send(.didEnterBackground) {
      $0.timer.pause(at: self.start)
      $0.pausedByBackground = true
    }

    // Nothing carries a session out of sight any more: half an hour away must move it nowhere.
    let back = start.addingTimeInterval(30 * 60)
    now.setValue(back)
    await store.send(.didBecomeActive) {
      $0.timer.resume(at: back)
      $0.pausedByBackground = false
      $0.lastWokeAt = back
    }
    await store.receive(.timerTicked(back)) { $0.now = back }

    XCTAssertEqual(store.state.currentStep, 0, "the slide the user left on is the slide they return to")
    XCTAssertEqual(store.state.remaining, 300, "and the step still has its full five minutes")

    await store.send(.onDisappear)
    await store.finish()
  }

  func testAPauseTheUserAskedForSurvivesTheTripToTheBackground() async {
    let clock = TestClock()
    let now = LockIsolated(start)

    let store = TestStore(initialState: makeRunningState()) {
      BalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
    }

    await store.send(.pauseToggled) { $0.timer.pause(at: self.start) }
    // Already paused, so backgrounding takes no pause of its own — and must not lift the user's.
    await store.send(.didEnterBackground)

    let back = start.addingTimeInterval(60)
    now.setValue(back)
    await store.send(.didBecomeActive) { $0.lastWokeAt = back }
    await store.receive(.timerTicked(back)) { $0.now = back }

    XCTAssertTrue(store.state.isPaused, "coming back must not start a session the user stopped")

    await store.send(.onDisappear)
    await store.finish()
  }

  func testCatchingUpPastTheLastStepCompletesTheFlow() async {
    let clock = TestClock()
    let now = LockIsolated(start)
    let steps = Step.part2

    let store = TestStore(initialState: makeRunningState(currentStep: steps.count - 2, steps: steps)) {
      BalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
      $0.dismiss = DismissEffect { }
    }

    let long = start.addingTimeInterval(60 * 60)
    now.setValue(long)
    // Coming back to the app counts as waking the screen.
    await store.send(.didBecomeActive) { $0.lastWokeAt = long }
    await store.receive(.timerTicked(long)) {
      $0.now = long
      _ = $0.timer.consumeElapsedSteps(at: long)
      $0.currentStep = steps.count - 1
    }
    await store.receive(.completeSteps) { $0.isCompleted = true }
    await store.receive(.markInitialProcessCompletedIfNeeded)
    await store.finish()
  }

  func testScreenRestsAfterTheChosenDelayAndWakesOnTheNextStep() async {
    let clock = TestClock()
    let now = LockIsolated(start)
    let dimmed = LockIsolated<[Bool]>([])

    let store = TestStore(initialState: makeRunningState(restEnabled: true, restDelay: 30)) {
      BalancingEnergy()
    } withDependencies: {
      $0.continuousClock = clock
      $0.date = .init { now.value }
      $0.screen.setDimmed = { value in dimmed.withValue { $0.append(value) } }
    }

    // Not yet: the step has only been on screen for 29 seconds.
    let early = start.addingTimeInterval(29)
    now.setValue(early)
    await store.send(.timerTicked(early)) { $0.now = early }

    let restDue = start.addingTimeInterval(30)
    now.setValue(restDue)
    await store.send(.timerTicked(restDue)) {
      $0.now = restDue
      $0.isResting = true
    }

    // The step falling due lights the screen back up — that is the point of resting.
    let stepDue = start.addingTimeInterval(300)
    now.setValue(stepDue)
    await store.send(.timerTicked(stepDue)) {
      $0.now = stepDue
      _ = $0.timer.consumeElapsedSteps(at: stepDue)
      $0.currentStep = 1
      $0.isResting = false
      $0.lastWokeAt = stepDue
    }
    await store.finish()

    XCTAssertEqual(dimmed.value, [true, false])
  }

  func testTappingTheRestingScreenBringsTheStepBack() async {
    let dimmed = LockIsolated<[Bool]>([])
    var state = makeRunningState(restEnabled: true)
    state.isResting = true

    let store = TestStore(initialState: state) {
      BalancingEnergy()
    } withDependencies: {
      $0.date = .constant(start)
      $0.screen.setDimmed = { value in dimmed.withValue { $0.append(value) } }
    }

    await store.send(.screenTapped) {
      $0.isResting = false
      $0.lastWokeAt = self.start
    }
    await store.finish()

    XCTAssertEqual(dimmed.value, [false])
  }

  func testTouchingAnAwakeScreenOnlyPostponesTheRest() async {
    let now = LockIsolated(start)
    let store = TestStore(initialState: makeRunningState(restEnabled: true, restDelay: 30)) {
      BalancingEnergy()
    } withDependencies: {
      $0.date = .init { now.value }
    }

    let touchedAt = start.addingTimeInterval(25)
    now.setValue(touchedAt)
    await store.send(.timerTicked(touchedAt)) { $0.now = touchedAt }
    await store.send(.screenTapped) { $0.lastWokeAt = touchedAt }

    // 30 s after the *touch*, not after the step appeared.
    let notYet = start.addingTimeInterval(50)
    now.setValue(notYet)
    await store.send(.timerTicked(notYet)) { $0.now = notYet }

    let restDue = start.addingTimeInterval(55)
    now.setValue(restDue)
    await store.send(.timerTicked(restDue)) {
      $0.now = restDue
      $0.isResting = true
    }
    await store.finish()
  }

  func testAPausedSessionNeverRests() async {
    let store = TestStore(initialState: makeRunningState(restEnabled: true, restDelay: 30)) {
      BalancingEnergy()
    } withDependencies: {
      $0.date = .constant(start)
    }

    await store.send(.pauseToggled) {
      $0.timer.pause(at: self.start)
      $0.lastWokeAt = self.start
    }

    // A paused session is one the user is looking at, so the screen stays lit.
    let long = start.addingTimeInterval(3_600)
    await store.send(.timerTicked(long)) { $0.now = long }
    XCTAssertFalse(store.state.isResting)
    await store.finish()
  }

  func testScreenRestDisabledKeepsTheScreenLit() async {
    let store = TestStore(initialState: makeRunningState(restEnabled: false)) {
      BalancingEnergy()
    } withDependencies: {
      $0.date = .constant(start)
    }

    let long = start.addingTimeInterval(240)
    await store.send(.timerTicked(long)) { $0.now = long }
    XCTAssertFalse(store.state.isResting)
    await store.finish()
  }

  func testLeavingTheSessionHandsTheScreenBack() async {
    let ended = LockIsolated(0)
    var state = makeRunningState(restEnabled: true)
    state.isResting = true

    let store = TestStore(initialState: state) {
      BalancingEnergy()
    } withDependencies: {
      $0.screen.endSession = { ended.withValue { $0 += 1 } }
    }

    await store.send(.onDisappear) { $0.isResting = false }
    await store.finish()

    XCTAssertEqual(ended.value, 1, "brightness and the idle timer must never be left held")
  }

  func testBackgroundingHandsTheScreenBackToo() async {
    let ended = LockIsolated(0)
    var state = makeRunningState(restEnabled: true)
    state.isResting = true

    let store = TestStore(initialState: state) {
      BalancingEnergy()
    } withDependencies: {
      $0.date = .constant(start)
      $0.screen.endSession = { ended.withValue { $0 += 1 } }
    }

    await store.send(.didEnterBackground) {
      $0.isResting = false
      $0.timer.pause(at: self.start)
      $0.pausedByBackground = true
    }
    await store.finish()

    XCTAssertEqual(ended.value, 1)
  }

  func testTurningScreenRestOffInSettingsWakesTheScreenAtOnce() async {
    var state = makeRunningState(restEnabled: true)
    state.isResting = true

    let store = TestStore(initialState: state) {
      BalancingEnergy()
    } withDependencies: {
      $0.date = .constant(start)
    }

    await store.send(.didTapSettings) { $0.destination = .settings(.init()) }
    await store.send(.destination(.presented(.settings(.screenRestEnabledChanged(false))))) {
      $0.destination = .settings(.init(screenRestEnabled: false))
      $0.restEnabled = false
      $0.isResting = false
      $0.lastWokeAt = self.start
    }
    await store.finish()
  }

  func testChangingTheRestDelayInSettingsAppliesToTheNextRest() async {
    let now = LockIsolated(start)
    let store = TestStore(initialState: makeRunningState(restEnabled: true, restDelay: 30)) {
      BalancingEnergy()
    } withDependencies: {
      $0.date = .init { now.value }
    }

    await store.send(.didTapSettings) { $0.destination = .settings(.init()) }
    await store.send(.destination(.presented(.settings(.screenRestDelayChanged(120))))) {
      $0.destination = .settings(.init(screenRestDelay: 120))
      $0.restDelay = 120
      $0.lastWokeAt = self.start
    }

    let oldDelay = start.addingTimeInterval(31)
    now.setValue(oldDelay)
    await store.send(.timerTicked(oldDelay)) { $0.now = oldDelay }
    XCTAssertFalse(store.state.isResting, "the old 30 s delay must no longer apply")

    let newDelay = start.addingTimeInterval(120)
    now.setValue(newDelay)
    await store.send(.timerTicked(newDelay)) {
      $0.now = newDelay
      $0.isResting = true
    }
    await store.finish()
  }

  // MARK: - Scene phase

  /// The complaint behind this: a glance at Control Center mid-meditation used to pause the session
  /// and throw the screen back to full brightness.
  func testAPassingInterruptionIsNotADeparture() {
    XCTAssertNil(
      BalancingEnergy.Action.forScenePhase(.inactive),
      "Control Center, the app switcher and a call banner all read as inactive, and none of them means the user left"
    )
  }

  func testLeavingTheAppStopsTheSessionAndReturningResumesIt() {
    XCTAssertEqual(BalancingEnergy.Action.forScenePhase(.background), .didEnterBackground)
    XCTAssertEqual(BalancingEnergy.Action.forScenePhase(.active), .didBecomeActive)
  }
}
