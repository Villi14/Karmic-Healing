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
      VStack(spacing: 32) {
        VStack(spacing: 16) {
          if let image = viewStore.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fit)
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
              .frame(height: 36)
          }
          VStack(spacing: 8) {
            Text(viewStore.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .font(.system(size: 16, weight: .medium))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 16)
            
            if let message = viewStore.message {
              Text(message)
                .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
                .font(.system(size: 14, weight: .regular))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
            }
          }
        }
        HStack(spacing: 8) {
          self.buttonsView(viewStore.buttons)
        }
      }
      .frame(maxHeight: 500)
      .multilineTextAlignment(.center)
      .padding(16)
      .fixedSize(horizontal: false, vertical: true)
      .background {
        Rectangle()
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
          .clipShape(
            RoundedRectangle(cornerRadius: 12)
          )
         .shadow(color: .black, radius: 200)

        RoundedRectangle(cornerRadius: 12)
          .inset(by: 0.5)
          .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.5), lineWidth: 0.5)
      }
      .padding(16)
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
              .frame(height: 48)
              .frame(maxWidth: .infinity)
              .background(ResourcesAsset.Colors.background.swiftUIColor)
            
          default:
            Text(button.label)
              .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
              .frame(height: 48)
              .frame(maxWidth: .infinity)
              .background(ResourcesAsset.Colors.clam.swiftUIColor)
          }
        }
      }
      .frame(maxWidth: 300)
      .font(.system(size: 16, weight: .semibold))
      .clipShape(RoundedRectangle(cornerRadius: 12))
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

