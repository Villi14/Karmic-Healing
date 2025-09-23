// KarmicHealing 2025

import SwiftUI
import Resources
import ComposableArchitecture

@Reducer
public struct AlertReducer<Action: Equatable> {
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
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: DesignConstants.spacingXLarge) {
        VStack(spacing: DesignConstants.spacing) {
          if let image = viewStore.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
              .frame(height: DesignConstants.frameHeightMedium)
          }
          VStack(spacing: DesignConstants.spacingSmall) {
            Text(viewStore.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .font(.callout.weight(.medium))
              .multilineTextAlignment(.center)
              .padding(.horizontal, DesignConstants.paddingLarge)
            
            if let message = viewStore.message {
              Text(message)
                .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
                .font(.callout)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, DesignConstants.paddingLarge)
            }
          }
        }
        HStack(spacing: DesignConstants.spacingSmall) {
          self.buttonsView(viewStore.buttons)
        }
      }
      .frame(maxHeight: DesignConstants.maxHeightLarge)
      .multilineTextAlignment(.center)
      .padding(DesignConstants.paddingLarge)
      .fixedSize(horizontal: false, vertical: true)
      .background {
        Rectangle()
          .fill(ResourcesAsset.Colors.background.swiftUIColor)
          .clipShape(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
          )
          .overlay(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
              .stroke(ResourcesAsset.Colors.textInvert.swiftUIColor, lineWidth: DesignConstants.lineWidth)
          )
          .shadow(color: .black, radius: DesignConstants.shadowRadiusLarge)
      }
      .padding(DesignConstants.paddingLarge)
    }
    .background {
      FullScreenCoverBackgroundView(backgroundColor: .clear)
    }
  }
  
  private func buttonsView(_ buttons: [AlertReducer<Action>.State.ButtonState]) -> some View {
    ForEach(buttons) { button in
      Button {
        if let action = button.action {
          store.send(action)
        }
        self.dismiss()
      } label: {
        Group {
          switch button.role {
          case .cancel:
            Text(button.label)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .frame(height: DesignConstants.frameHeightXLarge)
              .frame(maxWidth: .infinity)
              .background(ResourcesAsset.Colors.background.swiftUIColor)
            
          default:
            Text(button.label)
              .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
              .frame(height: DesignConstants.frameHeightXLarge)
              .frame(maxWidth: .infinity)
              .background(ResourcesAsset.Colors.clam.swiftUIColor)
          }
        }
      }
      .frame(maxWidth: DesignConstants.maxWidthMedium)
      .font(.subheadline.weight(.semibold))
      .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium))
    }
  }
}

#Preview {
  ZStack {
    BgWithGradientView()
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

