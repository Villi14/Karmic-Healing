//
// Karmic Healing 2025
//

import ComposableArchitecture
import ConcurrencyExtras
import XCTest
@testable import KarmicHealingWatch

@MainActor
final class WatchBalancingEnergyListTests: XCTestCase {
  func testEssentialSelfOpensPartTwo() async {
    let store = TestStore(initialState: WatchBalancingEnergyList.State()) {
      WatchBalancingEnergyList()
    }

    await store.send(.essentialSelf) {
      $0.balancingEnergy = .start(.essential)
    }
    await store.finish()
  }

  func testDivineSelfOpensPartThree() async {
    let store = TestStore(initialState: WatchBalancingEnergyList.State()) {
      WatchBalancingEnergyList()
    }

    await store.send(.divineSelf) {
      $0.balancingEnergy = .start(.divine)
    }
    await store.finish()
  }

  func testOpenSettingsLoadsStoredSettings() async {
    let store = TestStore(initialState: WatchBalancingEnergyList.State()) {
      WatchBalancingEnergyList()
    } withDependencies: {
      $0.watchUserDefaults.boolForKey = { _ in true }
      $0.watchUserDefaults.floatForKey = { _ in 0.3 }
      $0.watchUserDefaults.integerForKey = { _ in 10 }
      $0.watchUserDefaults.stringForKey = { _ in "uk" }
    }

    await store.send(.openSettings) {
      $0.settings = WatchSettings.State(
        soundEnabled: true,
        vibrationEnabled: true,
        audioVolume: 0.3,
        sessionDuration: 10,
        userLanguage: "uk",
        // The rest flag was never written, so it keeps its default; the delay shares the
        // integer stub with the duration.
        screenRestEnabled: true,
        screenRestDelay: 10
      )
    }
  }

  /// A watch updated from a build that queued the session tail must not keep buzzing through it.
  func testOpeningTheAppPurgesLeftoverSessionNotifications() async {
    let purges = LockIsolated(0)

    let store = TestStore(initialState: WatchBalancingEnergyList.State()) {
      WatchBalancingEnergyList()
    } withDependencies: {
      $0.watchNotification.purgeSessionNotifications = { purges.withValue { $0 += 1 } }
    }

    await store.send(.onAppear)
    await store.finish()

    XCTAssertEqual(purges.value, 1)
  }

  func testCompletingMeditationDismissesTheSession() async {
    let store = TestStore(initialState: WatchBalancingEnergyList.State()) {
      WatchBalancingEnergyList()
    }
    store.exhaustivity = .off

    await store.send(.essentialSelf)
    await store.send(.balancingEnergy(.presented(.completeSteps)))
    await store.finish()

    XCTAssertNil(store.state.balancingEnergy)
  }

  /// Swiping the cover away never reaches the session reducer, so the list has to let go of the
  /// runtime session itself — otherwise the watch holds the display awake for a meditation the
  /// user has already left, and still offers to resume it.
  func testSwipingTheSessionAwayReleasesTheRuntimeAndTheStoredProgress() async {
    let stops = LockIsolated(0)
    let storedFlags = LockIsolated<[String: Bool]>([:])

    let store = TestStore(initialState: WatchBalancingEnergyList.State()) {
      WatchBalancingEnergyList()
    } withDependencies: {
      $0.watchRuntime.stop = { stops.withValue { $0 += 1 } }
      $0.watchUserDefaults.setBool = { value, key in
        storedFlags.withValue { $0[key] = value }
      }
    }
    store.exhaustivity = .off

    await store.send(.essentialSelf)
    await store.send(.balancingEnergy(.dismiss))
    await store.finish()

    XCTAssertNil(store.state.balancingEnergy)
    XCTAssertEqual(stops.value, 1)
    XCTAssertEqual(storedFlags.value[WatchUserDefaultsClient.Keys.hasActiveMeditation], false)
  }

  func testASessionStartsOnItsFirstSlideCarryingItsOwnSteps() {
    let session = WatchBalancingEnergy.State.start(.divine)

    XCTAssertEqual(session.title, "divine_self")
    XCTAssertEqual(session.currentStep, 0)
    XCTAssertEqual(session.steps, Step.part3)
    XCTAssertFalse(session.isCompleted)
  }

  /// Resuming is offered from a step that was stored earlier, so a step from a part that has
  /// since grown shorter — or a nonsense one — has to land inside the session rather than past
  /// its end.
  func testResumingOutsideThePartLandsOnTheNearestSlide() {
    XCTAssertEqual(
      WatchBalancingEnergy.State.start(.essential, at: 99).currentStep,
      Step.part2.count - 1
    )
    XCTAssertEqual(WatchBalancingEnergy.State.start(.essential, at: -1).currentStep, 0)
    XCTAssertEqual(WatchBalancingEnergy.State.start(.essential, at: 3).currentStep, 3)
  }

  func testMeditationTypeRawValues() {
    XCTAssertEqual(MeditationType.essential.rawValue, "essential_self")
    XCTAssertEqual(MeditationType.divine.rawValue, "divine_self")
    XCTAssertEqual(MeditationType(rawValue: "initial_process"), nil)
    XCTAssertEqual(MeditationType.allCases.count, 2)
    XCTAssertEqual(MeditationType.essential.steps, Step.part2)
    XCTAssertEqual(MeditationType.divine.steps, Step.part3)
  }
}
