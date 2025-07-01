//
// Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import Common
import Resources

public struct OnboardingView: View {
  let store: StoreOf<Onboarding>

  public init(store: StoreOf<Onboarding>) {
    self.store = store
  }

  private struct ViewState: Equatable {
    init(state: Onboarding.State) {
      self.currentStep = state.currentStep
      self.steps = state.steps
    }

    let currentStep: Int
    let steps: [OnboardingStep]
  }

  public var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      ZStack {
        LinearGradient(
          gradient: Gradient(colors: [
            ResourcesAsset.Colors.clam.swiftUIColor.opacity(0.1),
            ResourcesAsset.Colors.background.swiftUIColor
          ]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack {
          TabView(selection: Binding(
            get: { viewStore.currentStep },
            set: { newValue in
              if newValue > viewStore.currentStep {
                viewStore.send(.nextStep)
              } else if newValue < viewStore.currentStep {
                viewStore.send(.previousStep)
              }
            }
          )) {
            ForEach(Array(viewStore.steps.enumerated()), id: \.offset) { index, step in
              VStack(spacing: 20) {
                Image(systemName: step.imageName)
                  .font(.system(size: 80))
                  .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
                  .padding()

                Text(step.title)
                  .font(.system(size: 24, weight: .medium))
                  .bold()
                  .multilineTextAlignment(.center)
                  .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

                Text(step.description)
                  .font(.system(size: 16, weight: .medium))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                  .padding(.horizontal)
              }
              .tag(index)
            }
          }
          .setTabViewdIndicatorColor
          .tabViewStyle(.page(indexDisplayMode: .always))
          .gesture(
            DragGesture()
              .onEnded { gesture in
                let threshold: CGFloat = 50
                if gesture.translation.width > threshold {
                  if viewStore.currentStep > 0 {
                    viewStore.send(.previousStep)
                  }
                } else if gesture.translation.width < -threshold {
                  if viewStore.currentStep < viewStore.steps.count - 1 {
                    viewStore.send(.nextStep)
                  }
                }
              }
          )

          HStack {
            if viewStore.currentStep > 0 {
              Button(String(localized: "back", bundle: .main)) {
                viewStore.send(.previousStep)
              }
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .padding()
            }

            Spacer()

            Button(viewStore.currentStep == viewStore.steps.count - 1 ?
                   String(localized: "done", bundle: .main) :
                    String(localized: "next", bundle: .main)) {
              viewStore.send(.nextStep)
            }
            .padding()
            .background(ResourcesAsset.Colors.clam.swiftUIColor)
            .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
            .cornerRadius(12)
          }
          .padding()
        }
      }
    }
  }
}

#Preview {
  OnboardingView(store: .init(
    initialState: .init(),
    reducer: {
      Onboarding()
    }
  ))
}
