//
// Karmic Healing 2025
//

import Dependencies
import Foundation

extension DependencyValues {
  public var analytics: AnalyticsClient {
    get { self[AnalyticsClient.self] }
    set { self[AnalyticsClient.self] = newValue }
  }
}

public struct AnalyticsClient {
  public var trackEvent: @Sendable (AnalyticsEvent) -> Void
  public var trackScreen: @Sendable (String) -> Void
  public var setUserProperty: @Sendable (String, String) -> Void
  
  public init(
    trackEvent: @Sendable @escaping (AnalyticsEvent) -> Void,
    trackScreen: @Sendable @escaping (String) -> Void,
    setUserProperty: @Sendable @escaping (String, String) -> Void
  ) {
    self.trackEvent = trackEvent
    self.trackScreen = trackScreen
    self.setUserProperty = setUserProperty
  }
}

extension AnalyticsClient: DependencyKey {
  public static let liveValue: Self = {
    return Self(
      trackEvent: { event in
        // Тут можна інтегрувати з Firebase Analytics, Mixpanel, тощо
        print("📊 Analytics Event: \(event.name) - \(event.properties)")
      },
      trackScreen: { screenName in
        print("📊 Screen View: \(screenName)")
      },
      setUserProperty: { key, value in
        print("📊 User Property: \(key) = \(value)")
      }
    )
  }()
  
  public static let testValue: Self = {
    return Self(
      trackEvent: { _ in },
      trackScreen: { _ in },
      setUserProperty: { _, _ in }
    )
  }()
}

public struct AnalyticsEvent {
  public let name: String
  public let properties: [String: Any]
  
  public init(name: String, properties: [String: Any] = [:]) {
    self.name = name
    self.properties = properties
  }
}

// MARK: - Predefined events
extension AnalyticsEvent {
  public static func onboardingStarted() -> Self {
    .init(name: "onboarding_started")
  }
  
  public static func onboardingCompleted() -> Self {
    .init(name: "onboarding_completed")
  }
  
  public static func energyBalancingStarted(type: String) -> Self {
    .init(name: "energy_balancing_started", properties: ["type": type])
  }
  
  public static func energyBalancingCompleted(type: String, stepsCompleted: Int) -> Self {
    .init(name: "energy_balancing_completed", properties: [
      "type": type,
      "steps_completed": stepsCompleted
    ])
  }
  
  public static func requestCreated(title: String) -> Self {
    .init(name: "request_created", properties: ["title": title])
  }
  
  public static func settingsChanged(setting: String, value: String) -> Self {
    .init(name: "settings_changed", properties: [
      "setting": setting,
      "value": value
    ])
  }
} 