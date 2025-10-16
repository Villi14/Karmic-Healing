//
// Karmic Healing 2025
//

import ComposableArchitecture
import Foundation
import WatchKit

@Reducer
public struct WatchBalancingEnergy {
  @Dependency(\.watchUserDefaults) var userDefaults
  @Dependency(\.continuousClock) var clock
  @Dependency(\.audio) var audio
  @Dependency(\.watchNotification) var notification

  private enum CancelID { case timer }

  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents var destination: Destination.State?
    public let title: String
    public var currentStep: Int
    public var isCompleted: Bool
    public let steps: [Step]
    public var remainingTime: Int
    public var isTimerActive: Bool

    public init(
      title: String,
      currentStep: Int,
      isCompleted: Bool,
      steps: [Step],
      remainingTime: Int = 0,
      isTimerActive: Bool = false
    ) {
      self.title = title
      self.currentStep = currentStep
      self.isCompleted = isCompleted
      self.steps = steps
      self.remainingTime = remainingTime
      self.isTimerActive = isTimerActive
    }
  }

  public enum Action: Equatable {
    case onAppear
    case nextStep
    case previousStep
    case completeSteps
    case autoScrollTimer
    case userManuallyScrolled
    case didTapSettings
    case startTimer
    case onDisappear
    case manualScrollStarted
    case manualScrollEnded
    case destination(PresentationAction<Destination.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          let granted = await notification.requestAuthorization()
          if granted {
            await send(.startTimer)
          }
        }

      case .nextStep:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
          // Cancel existing notifications when user manually scrolls
          print("WatchBalancingEnergy: Manual next step - cancelling notifications")
          notification.cancelBalancingEnergyNotifications()
          return .concatenate(
            .run { _ in
              await playSoundAndVibrate()
            },
            .cancel(id: CancelID.timer),
            .run { send in
              // Wait a bit for scroll to complete, then restart timer
              try await clock.sleep(for: .milliseconds(500))
              await send(.manualScrollEnded)
            }
          )
        } else {
          return .send(.completeSteps)
        }

      case .previousStep:
        if state.currentStep > 0 {
          state.currentStep -= 1
          // Cancel existing notifications when user manually scrolls
          print("WatchBalancingEnergy: Manual previous step - cancelling notifications")
          notification.cancelBalancingEnergyNotifications()
          return .concatenate(
            .run { _ in
              await playSoundAndVibrate()
            },
            .cancel(id: CancelID.timer),
            .run { send in
              // Wait a bit for scroll to complete, then restart timer
              try await clock.sleep(for: .milliseconds(500))
              await send(.manualScrollEnded)
            }
          )
        }
        return .none

      case .autoScrollTimer:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
          print("WatchBalancingEnergy: Auto scroll to step \(state.currentStep)")
          return .run { _ in
            await playSoundAndVibrate()
          }
          .merge(with: startAutoScrollTimer(currentStep: state.currentStep, title: state.title, remainingTime: state.remainingTime))
        } else {
          return .send(.completeSteps)
        }

      case .userManuallyScrolled:
        // Cancel existing notifications when user manually scrolls
        print("WatchBalancingEnergy: Manual scroll - cancelling notifications")
        notification.cancelBalancingEnergyNotifications()
        // Reset timer when user manually scrolls
        return .concatenate(
          .cancel(id: CancelID.timer),
          startAutoScrollTimer(currentStep: state.currentStep, title: state.title, remainingTime: state.remainingTime)
        )

      case .completeSteps:
        state.isCompleted = true
        // Cancel notifications when completing steps
        notification.cancelBalancingEnergyNotifications()
        return .cancel(id: CancelID.timer)

      case .didTapSettings:
        state.destination = .settings(.init())
        return .none

      case .startTimer:
        return startAutoScrollTimer(currentStep: state.currentStep, title: state.title, remainingTime: state.remainingTime)

      case .onDisappear:
        // Save current meditation state when leaving screen
        let title = state.title
        let currentStep = state.currentStep
        let isCompleted = state.isCompleted
        return .run { _ in
          await saveMeditationState(title: title, currentStep: currentStep, isCompleted: isCompleted)
          // Notifications are already scheduled in startAutoScrollTimer
        }

      case .manualScrollStarted:
        return .cancel(id: CancelID.timer)

      case .manualScrollEnded:
        return startAutoScrollTimer(currentStep: state.currentStep, title: state.title, remainingTime: state.remainingTime)

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }

  private func playSoundAndVibrate() async {
    // Use only local Watch settings
    let soundEnabled = userDefaults.bool(for: .soundEnabled)
    let vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
    let currentVolume = userDefaults.float(for: .audioVolume)
    
    print("🔊 WatchBalancingEnergy: Sound settings - enabled: \(soundEnabled), volume: \(currentVolume), vibration: \(vibrationEnabled)")
    
    // Check local Watch UserDefaults
    print("🔍 WatchBalancingEnergy: Local Watch UserDefaults:")
    print("  soundEnabled: \(userDefaults.bool(for: .soundEnabled))")
    print("  vibrationEnabled: \(userDefaults.bool(for: .vibrationEnabled))")
    print("  audioVolume: \(userDefaults.float(for: .audioVolume))")
    print("  sessionDuration: \(userDefaults.integer(for: .sessionDuration))")
    print("  userLanguage: \(userDefaults.string(for: .userLanguage) ?? "nil")")
    
    // Use current volume, don't override with 0.5
    let volumeToUse = currentVolume
    print("🔊 WatchBalancingEnergy: Using volume: \(volumeToUse) (from UserDefaults)")

    // Play vibration separately from sound
    await playVibration(vibrationEnabled: vibrationEnabled)
    
    // Play sound separately from vibration
    await playSound(soundEnabled: soundEnabled, volume: volumeToUse)
  }
  
  private func playVibration(vibrationEnabled: Bool) async {
    await MainActor.run {
        if vibrationEnabled {
          // Add additional haptic feedback for stronger effect
          Task {
            try await clock.sleep(for: .milliseconds(500))
            WKInterfaceDevice.current().play(.click)
          }
        } else {
      }
    }
  }
  
  private func playSound(soundEnabled: Bool, volume: Float) async {
    print("🔊 WatchBalancingEnergy: playSound called - enabled: \(soundEnabled), volume: \(volume)")
    if soundEnabled {
      print("🔊 WatchBalancingEnergy: Setting volume and playing sound")
      audio.setVolume(volume)
      audio.playSound("ding", "wav")
      print("🔊 WatchBalancingEnergy: Sound play command sent")
    } else {
      print("🔊 WatchBalancingEnergy: Sound disabled, skipping")
    }
  }

  private func saveMeditationState(title: String, currentStep: Int, isCompleted: Bool) async {
    await userDefaults.setAsync(title, for: .activeMeditationTitle)
    await userDefaults.setAsync(currentStep, for: .activeMeditationStep)
    await userDefaults.setAsync(isCompleted, for: .activeMeditationCompleted)
    await userDefaults.setAsync(true, for: .hasActiveMeditation)
    print("WatchBalancingEnergy: Saved meditation state - title: \(title), step: \(currentStep), completed: \(isCompleted)")
  }

  private func startAutoScrollTimer(currentStep: Int, title: String, remainingTime: Int) -> Effect<Action> {
    let durationToUse = remainingTime > 0 ? remainingTime / 60 : 5 // Convert seconds to minutes, default 5 minutes

    return .run { send in
      print("WatchBalancingEnergy: Starting auto scroll timer with duration: \(durationToUse) minutes")
      
      // Schedule local notification to wake up the app when timer expires
      // Pass currentStep + 1 because notification should open the NEXT step
      let nextStep = currentStep + 1
      print("WatchBalancingEnergy: Scheduling notification for step \(nextStep) (current: \(currentStep))")
      let userLanguage = userDefaults.string(for: .userLanguage) ?? "en"
      notification.scheduleLocalNotification(
        "time_to_flip_slide".localized(for: Locale(identifier: userLanguage)),
        "tap_to_continue_energy_balancing".localized(for: Locale(identifier: userLanguage)),
        TimeInterval(durationToUse * 60),
        .balancingEnergy,
        title,
        nextStep
      )
      
      try await clock.sleep(for: .seconds(durationToUse * 60))
      await send(.autoScrollTimer)
    }
    .cancellable(id: CancelID.timer)
  }
}

@Reducer
public struct Destination {
  @ObservableState
  public enum State: Equatable {
    case settings(EmptyState)
  }

  public enum Action: Equatable {
    case settings(EmptyAction)
  }

  public var body: some ReducerOf<Self> {
    EmptyReducer()
  }
}

public struct EmptyState: Equatable {}
public enum EmptyAction: Equatable {}

