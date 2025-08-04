//
// Karmic Healing 2025
//

import ComposableArchitecture
import Common
import UIKit
import Foundation
import AVFoundation

@Reducer
public struct BalancingEnergy {
  @Dependency(\.userDefaults) var userDefaults
  @Dependency(\.continuousClock) var clock
  @Dependency(\.audio) var audio
  @Dependency(\.notification) var notification

  private enum CancelID { case timer }

  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents var destination: Destination.State?
    let title: String
    var currentStep: Int
    var isCompleted: Bool
    let steps: [Step]

    public init(
      title: String,
      currentStep: Int,
      isCompleted: Bool,
      steps: [Step]
    ) {
      self.title = title
      self.currentStep = currentStep
      self.isCompleted = isCompleted
      self.steps = steps
    }
  }

  public enum Action: Equatable {
    case onAppear
    case nextStep
    case previousStep
    case completeSteps
    case didTapSettings
    case autoScrollTimer
    case userManuallyScrolled
    case startTimer
    case onDisappear
    case destination(PresentationAction<Destination.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Request notification permission and start auto-scroll timer
        return .run { send in
          let granted = await notification.requestAuthorization()
          if granted {
            await send(.startTimer)
          }
        }

      case .nextStep:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
          // Play sound and vibrate
          return .run { _ in
            await playSoundAndVibrate()
          }
        } else {
          return .send(.completeSteps)
        }

      case .previousStep:
        if state.currentStep > 0 {
          state.currentStep -= 1
          // Play sound and vibrate
          return .run { _ in
            await playSoundAndVibrate()
          }
        }
        return .none

      case .completeSteps:
        state.isCompleted = true
        return .none
        
      case .didTapSettings:
        state.destination = .settings(.init())
        return .none

      case .autoScrollTimer:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
          return .run { _ in
            await playSoundAndVibrate()
          }
          .merge(with: startAutoScrollTimer())
        } else {
          return .send(.completeSteps)
        }
        
      case .userManuallyScrolled:
        // Reset timer when user manually scrolls
        return startAutoScrollTimer()
        
      case .startTimer:
        return startAutoScrollTimer()
        
      case .onDisappear:
        // Cancel all notifications when leaving the screen
        notification.cancelAllNotifications()
        return .cancel(id: CancelID.timer)

      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }
  
  private func playSoundAndVibrate() async {
    // Get current settings from UserDefaults to ensure we have the latest values
    let soundEnabled = userDefaults.bool(for: .soundEnabled)
    let vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
    let currentVolume = userDefaults.float(for: .audioVolume)
    
    if soundEnabled {
      audio.setVolume(currentVolume)
      audio.playSound("ding", "wav")
    }
    
    // Trigger haptic feedback if enabled
    if vibrationEnabled {
      await MainActor.run {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
      }
    }
  }

  private func startAutoScrollTimer() -> Effect<Action> {
    let savedDuration = userDefaults.integer(for: .sessionDuration)
    let durationToUse = savedDuration > 0 ? savedDuration : 5 // Default 5 minutes
    
    // Schedule local notification to wake up the app
    notification.scheduleLocalNotification(
      "Час перегорнути слайд",
      "Натисніть щоб продовжити балансування енергії",
      TimeInterval(durationToUse * 60)
    )
    
    return .run { send in
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
    case settings(EnergyBalansingSettings.State)
  }
  
  public enum Action: Equatable {
    case settings(EnergyBalansingSettings.Action)
  }
  
  public var body: some ReducerOf<Self> {
    Scope(state: \.settings, action: \.settings) {
      EnergyBalansingSettings()
    }
  }
}
