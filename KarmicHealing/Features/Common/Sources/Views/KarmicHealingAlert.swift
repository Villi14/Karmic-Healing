//
// Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct KarmicHealingAlert<Action: Equatable> {
  public init() {}

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    return .none
  }

  public struct State: Equatable {
    let image: Image?
    let title: String
    let message: String?
    let buttons: [ButtonState]
    let style: AlertStyle

    public init(
      image: Image? = nil,
      title: String,
      message: String? = nil,
      buttons: [ButtonState] = [],
      style: AlertStyle = .default
    ) {
      self.image = image
      self.title = title
      self.message = message
      self.style = style

      if !buttons.isEmpty {
        self.buttons = buttons
      } else {
        self.buttons = [ .init(label: "OK")]
      }
    }

    public init(
      image: (() -> Image?)? = nil,
      title: () -> String,
      message: (() -> String)? = nil,
      buttons: (() -> [ButtonState])? = nil,
      style: AlertStyle = .default
    ) {
      self = .init(
        image: image?(),
        title: title(),
        message: message?(),
        buttons: buttons?() ?? [],
        style: style
      )
    }

    public struct ButtonState: Equatable, Identifiable {
      public let id = UUID()
      let label: String
      let action: Action?
      let role: Role?

      public init(label: String, action: Action? = nil, role: Role? = nil) {
        self.label = label
        self.action = action
        self.role = role
      }

      public enum Role: Sendable {
        case cancel
        case destructive
      }

      public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.action == rhs.action
        && lhs.label == rhs.label
        && lhs.role == rhs.role
      }
    }
    
    public enum AlertStyle: Equatable {
      case `default`
      case success
      case warning
      case error
      case info
    }
  }
}

// MARK: - Convenience initializers
extension KarmicHealingAlert.State {
  public static func success(
    title: String,
    message: String? = nil,
    buttons: [ButtonState] = []
  ) -> Self {
    .init(
      image: Image(systemName: "checkmark.circle.fill"),
      title: title,
      message: message,
      buttons: buttons,
      style: .success
    )
  }
  
  public static func error(
    title: String,
    message: String? = nil,
    buttons: [ButtonState] = []
  ) -> Self {
    .init(
      image: Image(systemName: "exclamationmark.triangle.fill"),
      title: title,
      message: message,
      buttons: buttons,
      style: .error
    )
  }
  
  public static func warning(
    title: String,
    message: String? = nil,
    buttons: [ButtonState] = []
  ) -> Self {
    .init(
      image: Image(systemName: "exclamationmark.triangle"),
      title: title,
      message: message,
      buttons: buttons,
      style: .warning
    )
  }
  
  public static func info(
    title: String,
    message: String? = nil,
    buttons: [ButtonState] = []
  ) -> Self {
    .init(
      image: Image(systemName: "info.circle"),
      title: title,
      message: message,
      buttons: buttons,
      style: .info
    )
  }
}
