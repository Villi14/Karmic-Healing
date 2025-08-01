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
  @Dependency(\.mainQueue) var mainQueue
  @Dependency(\.continuousClock) var clock
  @Dependency(\.audio) var audio

  private enum CancelID { case timer }

  public init() {}

  @ObservableState
  public struct State: Equatable {
    let title: String
    var currentStep: Int
    var isCompleted: Bool
    let steps: [Step]
    var sessionDuration: Int = 5
    var autoScrollTimer: Timer?
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true

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
    case nextStep
    case previousStep
    case completeSteps
    case onAppear
    case onDisappear
    case autoScrollTimer
    case userManuallyScrolled
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .nextStep:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
          // Play sound and vibrate
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled)
          }
        } else {
          return .send(.completeSteps)
        }

      case .previousStep:
        if state.currentStep > 0 {
          state.currentStep -= 1
          // Play sound and vibrate
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled)
          }
        }
        return .none

      case .completeSteps:
        state.isCompleted = true
        return .none
        
      case .onAppear:
        // Load session duration from UserDefaults
        let savedDuration = userDefaults.integer(for: .sessionDuration)
        if savedDuration > 0 {
          state.sessionDuration = savedDuration
        }

        // Start auto-scroll timer using the loaded duration
        let durationToUse = savedDuration > 0 ? savedDuration : state.sessionDuration
        return .run { _ in
          try await Task.sleep(nanoseconds: UInt64(durationToUse * 60 * 1_000_000_000))
        }
        .cancellable(id: CancelID.timer)
        .map { _ in .autoScrollTimer }

      case .onDisappear:
        // Cancel timer when view disappears
        return .cancel(id: CancelID.timer)
        
      case .autoScrollTimer:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
          let savedDuration = userDefaults.integer(for: .sessionDuration)
          let durationToUse = savedDuration > 0 ? savedDuration : state.sessionDuration
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled)
            try await Task.sleep(nanoseconds: UInt64(durationToUse * 60 * 1_000_000_000))
          }
          .cancellable(id: CancelID.timer)
          .map { _ in .autoScrollTimer }
        } else {
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled)
          }
          .merge(with: .send(.completeSteps))
        }
        
      case .userManuallyScrolled:
        // Reset timer when user manually scrolls
        let savedDuration = userDefaults.integer(for: .sessionDuration)
        let durationToUse = savedDuration > 0 ? savedDuration : state.sessionDuration
        return .run { _ in
          try await clock.sleep(for: .seconds(durationToUse * 60))
        }
        .cancellable(id: CancelID.timer)
        .map { _ in .autoScrollTimer }
      }
    }
  }
  
  private func playSoundAndVibrate(soundEnabled: Bool, vibrationEnabled: Bool) async {
    if soundEnabled {
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
}
