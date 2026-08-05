//
// Karmic Healing 2025
//

import Common
import ComposableArchitecture
import XCTest
@testable import Onboarding

@MainActor
final class OnboardingTests: XCTestCase {
  func testNextStepAdvancesUntilTheLastStep() async {
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding()
    }

    await store.send(.nextStep) { $0.currentStep = 1 }
    await store.send(.nextStep) { $0.currentStep = 2 }
    await store.send(.nextStep) { $0.currentStep = 3 }
  }

  func testNextStepOnLastStepCompletesOnboarding() async {
    let store = TestStore(initialState: Onboarding.State(currentStep: 3)) {
      Onboarding()
    } withDependencies: {
      $0.userDefaults.setBool = { _, _ in }
    }

    await store.send(.nextStep)
    await store.receive(.completeOnboarding) {
      $0.isCompleted = true
    }
    XCTAssertEqual(store.state.currentStep, 3)
  }

  func testPreviousStepGoesBack() async {
    let store = TestStore(initialState: Onboarding.State(currentStep: 2)) {
      Onboarding()
    }

    await store.send(.previousStep) { $0.currentStep = 1 }
    await store.send(.previousStep) { $0.currentStep = 0 }
  }

  func testPreviousStepOnFirstStepIsNoOp() async {
    let store = TestStore(initialState: Onboarding.State()) {
      Onboarding()
    }

    await store.send(.previousStep)
    XCTAssertEqual(store.state.currentStep, 0)
  }

  func testDefaultStepsAreTheFourOnboardingScreens() {
    let state = Onboarding.State()

    XCTAssertEqual(state.steps.count, 4)
    XCTAssertEqual(state.steps.map(\.imageName), ["book.closed", "sparkles", "heart", "star"])
    XCTAssertTrue(state.steps[0].showSkipButton)
    XCTAssertFalse(state.steps.dropFirst().contains { $0.showSkipButton })
    XCTAssertFalse(state.isCompleted)
  }
}
