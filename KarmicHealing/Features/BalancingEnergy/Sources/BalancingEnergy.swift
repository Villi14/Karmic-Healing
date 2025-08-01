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
    @Presents var destination: Destination.State?
    let title: String
    var currentStep: Int
    var isCompleted: Bool
    let steps: [Step]
    var sessionDuration: Int = 5
    var autoScrollTimer: Timer?
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true
    var audioVolume: Float = 1.0

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
    case didTapSettings
    case onAppear
    case onDisappear
    case autoScrollTimer
    case userManuallyScrolled
    case destination(PresentationAction<Destination.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .nextStep:
        if state.currentStep < state.steps.count - 1 {
          state.currentStep += 1
          // Play sound and vibrate
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled, audioVolume = state.audioVolume] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled, audioVolume: audioVolume)
          }
        } else {
          return .send(.completeSteps)
        }

      case .previousStep:
        if state.currentStep > 0 {
          state.currentStep -= 1
          // Play sound and vibrate
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled, audioVolume = state.audioVolume] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled, audioVolume: audioVolume)
          }
        }
        return .none

      case .completeSteps:
        state.isCompleted = true
        return .none
        
      case .didTapSettings:
        state.destination = .settings(.init())
        return .none
        
      case .onAppear:
        // Load session duration from UserDefaults
        let savedDuration = userDefaults.integer(for: .sessionDuration)
        if savedDuration > 0 {
          state.sessionDuration = savedDuration
        }
        
        // Load audio settings
        state.soundEnabled = userDefaults.bool(for: .soundEnabled)
        state.vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
        state.audioVolume = userDefaults.float(for: .audioVolume)

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
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled, audioVolume = state.audioVolume] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled, audioVolume: audioVolume)
            try await Task.sleep(nanoseconds: UInt64(durationToUse * 60 * 1_000_000_000))
          }
          .cancellable(id: CancelID.timer)
          .map { _ in .autoScrollTimer }
        } else {
          return .run { [soundEnabled = state.soundEnabled, vibrationEnabled = state.vibrationEnabled, audioVolume = state.audioVolume] _ in
            await playSoundAndVibrate(soundEnabled: soundEnabled, vibrationEnabled: vibrationEnabled, audioVolume: audioVolume)
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
        
      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }
  
  private func playSoundAndVibrate(soundEnabled: Bool, vibrationEnabled: Bool, audioVolume: Float) async {
    if soundEnabled {
      audio.setVolume(audioVolume)
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
