// KarmicHealing 2025

import SwiftUI
import Resources
import ComposableArchitecture

@Reducer
public struct AlertReducer<AlertAction: Equatable> {
  public typealias Action = AlertAction

  public init() {}
  
  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
  
  @ObservableState
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
      let action: AlertAction?
      let role: Role?
      
      public init(label: String, action: AlertAction? = nil, role: Role? = nil) {
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
extension AlertReducer.State {
  public static func success(
    title: String,
    message: String? = nil,
    buttons: [ButtonState] = []
  ) -> Self {
    .init(
      image: Image(systemName: "checkmark.circle"),
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
      image: Image(systemName: "exclamationmark.triangle"),
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

public struct AlertView<Action: Equatable>: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  
  let store: Store<AlertReducer<Action>.State, Action>
  
  public init(store: Store<AlertReducer<Action>.State, Action>) {
    self.store = store
  }
  
  public var body: some View {
    VStack(spacing: DesignConstants.spacingXLarge) {
        VStack(spacing: DesignConstants.spacing) {
          if let image = store.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundStyle(AuraGradient.gradient(for: level(for: store.style)))
              .frame(height: DesignConstants.frameHeightMedium)
          }
          VStack(spacing: DesignConstants.spacingSmall) {
            Text(store.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .font(Typography.title)
              .multilineTextAlignment(.center)
              .padding(.horizontal, DesignConstants.paddingLarge)
            
            if let message = store.message {
              Text(message)
                .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                .font(Typography.bodySecondary)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, DesignConstants.paddingLarge)
            }
          }
        }
        VStack(spacing: DesignConstants.spacingSmall) {
          self.buttonsView(store.buttons, tone: tone(for: store.style))
        }
      }
      .frame(maxHeight: DesignConstants.maxHeightLarge)
      .multilineTextAlignment(.center)
      .padding(DesignConstants.paddingLarge)
      .fixedSize(horizontal: false, vertical: true)
      .cardStyle(
        tone: tone(for: store.style),
        showsWatermark: true,
        gradient: AuraGradient.gradient(for: level(for: store.style))
      )
      .padding(DesignConstants.paddingLarge)
      .karmicContentWidth(DesignConstants.maxAlertWidth)
      .background {
        FullScreenCoverBackgroundView(backgroundColor: .clear)
      }
  }
  
  /// An alert takes the level its meaning sits on: a warning at the root,
  /// a confirmation at the heart, an explanation at the crown.
  private func tone(for style: AlertReducer<Action>.State.AlertStyle) -> Color {
    level(for: style).color
  }

  private func level(for style: AlertReducer<Action>.State.AlertStyle) -> Spectrum {
    switch style {
    case .error, .warning: .root
    case .success: .heart
    case .info: .crown
    case .default: .throat
    }
  }

  private func buttonsView(
    _ buttons: [AlertReducer<Action>.State.ButtonState],
    tone: Color
  ) -> some View {
    ForEach(buttons) { button in
      Button {
        if let action = button.action {
          store.send(action)
        }
        self.dismiss()
      } label: {
        // Stacked buttons share the card's width, so a long label wraps inside
        // the button instead of being truncated to fit a shared row.
        Text(button.label)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(
        .karmic(
          tone: button.role == .destructive ? Spectrum.root.color : tone,
          prominence: button.role == .cancel ? .quiet : .filled
        )
      )
    }
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .root)
    KarmicHealingAlertPreviewView()
  }
}

private struct KarmicHealingAlertPreviewView: View {
  var body: some View {
    AlertView<Action>(
      store: .init(
        initialState: .init(
          image: Image(systemName: "exclamationmark.triangle"),
          title: "Whoops! Something went wrong",
          message: "Thanks for your patience!",
          buttons: [
            AlertReducer<Action>.State.ButtonState(label: "Try Again"),
            AlertReducer<Action>.State.ButtonState(label: "Cancel", role: .cancel)
          ]
        ),
        reducer: {}
      )
    )
  }
  
  private enum Action: Equatable { }
}
