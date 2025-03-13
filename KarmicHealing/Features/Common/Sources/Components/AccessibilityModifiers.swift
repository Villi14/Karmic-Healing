//
// Karmic Healing 2025
//

import SwiftUI

public extension View {
  func karmicHealingAccessibility(
    label: String? = nil,
    hint: String? = nil,
    traits: AccessibilityTraits = [],
    isModal: Bool = false
  ) -> some View {
    self
      .accessibilityLabel(label ?? "")
      .accessibilityHint(hint ?? "")
      .accessibilityAddTraits(traits)
      .accessibilityElement(children: .combine)
      .if(isModal) { view in
        view.accessibilityAddTraits(.isModal)
      }
  }
  
  func karmicHealingButtonAccessibility(
    label: String,
    hint: String? = nil
  ) -> some View {
    self
      .karmicHealingAccessibility(
        label: label,
        hint: hint,
        traits: .isButton
      )
  }
  
  func karmicHealingHeaderAccessibility(
    label: String
  ) -> some View {
    self
      .karmicHealingAccessibility(
        label: label,
        traits: .isHeader
      )
  }
  
  func karmicHealingImageAccessibility(
    label: String,
    hint: String? = nil
  ) -> some View {
    self
      .karmicHealingAccessibility(
        label: label,
        hint: hint,
        traits: .isImage
      )
  }
}

// MARK: - Conditional modifier
extension View {
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

// MARK: - VoiceOver announcements
public struct VoiceOverAnnouncement {
  public static func announce(_ message: String) {
    UIAccessibility.post(notification: .announcement, argument: message)
  }
  
  public static func announceScreenChange(_ screenName: String) {
    UIAccessibility.post(notification: .screenChanged, argument: screenName)
  }
  
  public static func announceLayoutChange() {
    UIAccessibility.post(notification: .layoutChanged, argument: nil)
  }
}

// MARK: - Dynamic Type support
public extension View {
  func karmicHealingDynamicType() -> some View {
    self
      .dynamicTypeSize(.xSmall ... .accessibility3)
  }
  
  func karmicHealingScalableFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
    self
      .font(.system(size: size, weight: weight, design: .default))
      .karmicHealingDynamicType()
  }
}

// MARK: - High contrast support
public extension View {
  func karmicHealingHighContrast() -> some View {
    self
      .environment(\.colorSchemeContrast, .increased)
  }
}

// MARK: - Reduce motion support
public extension View {
  func karmicHealingReduceMotion() -> some View {
    self
      .environment(\.accessibilityReduceMotion, true)
  }
} 