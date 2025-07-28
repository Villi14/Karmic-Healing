// KarmicHealing 2025

import SwiftUI
import Resources
import ComposableArchitecture

public struct KarmicHealingAlertView<Action: Equatable>: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  
  let store: Store<KarmicHealingAlert<Action>.State, Action>
  
  public init(store: Store<KarmicHealingAlert<Action>.State, Action>) {
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
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
          .clipShape(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
          )
         .shadow(color: .black, radius: DesignConstants.shadowRadiusLarge)

//        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
//          .inset(by: DesignConstants.lineWidthThin)
//          .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(DesignConstants.opacityMedium), lineWidth: DesignConstants.lineWidthThin)
      }
      .padding(DesignConstants.paddingLarge)
    }
    .background {
      FullScreenCoverBackgroundView(backgroundColor: .clear)
    }
  }
  
  private func buttonsView(_ buttons: [KarmicHealingAlert<Action>.State.ButtonState]) -> some View {
    ForEach(buttons) { button in
      Button {
        if let action = button.action {
          self.store.send(action)
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
    SwiftUI.Color.white
      .ignoresSafeArea()
    KarmicHealingAlertPreviewView()
  }
}

private struct KarmicHealingAlertPreviewView: View {
  var body: some View {
    KarmicHealingAlertView<Action>(
      store: .init(
        initialState: .init(
          image: Image(systemName: "exclamationmark.triangle"),
          title: "Whoops! Something went wrong",
          message: "Thanks for your patience!",
          buttons: [
            KarmicHealingAlert<Action>.State.ButtonState(label: "Try Again"),
            KarmicHealingAlert<Action>.State.ButtonState(label: "Cancel", role: .cancel)
          ]
        ),
        reducer: {}
      )
    )
  }
  
  private enum Action: Equatable { }
}

