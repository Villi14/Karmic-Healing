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
        BgWithGradientView()

        VStack {
          HStack {
            Spacer()
            if viewStore.steps.indices.contains(viewStore.currentStep) && viewStore.steps[viewStore.currentStep].showSkipButton {
              Button("skip".loc()) {
                viewStore.send(.completeOnboarding)
              }
              .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              .font(.body.weight(.medium))
              .padding([.top, .trailing], DesignConstants.paddingLarge)
            }
          }

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
              VStack(spacing: DesignConstants.spacingLarge) {
                Image(systemName: step.imageName)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(height: DesignConstants.helpIconSize)
                  .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
                  .padding(DesignConstants.paddingLarge)

                Text(step.title)
                  .font(.title.weight(.bold))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
                  .padding(.horizontal, DesignConstants.paddingLarge)

                Text(step.description)
                  .font(.body.weight(.medium))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                  .padding(.horizontal, DesignConstants.paddingLarge)
                  .lineSpacing(DesignConstants.spacingSmall)
              }
              .tag(index)
            }
          }
          .setTabViewdIndicatorColor
          .tabViewStyle(.page(indexDisplayMode: .always))
          .gesture(
            DragGesture()
              .onEnded { gesture in
                let threshold: CGFloat = DesignConstants.thresholdMedium
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
              Button("back".loc()) {
                viewStore.send(.previousStep)
              }
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .font(.body.weight(.medium))
              .padding(DesignConstants.paddingLarge)
            }

            Spacer()

            Button(viewStore.currentStep == viewStore.steps.count - 1 ?
                   "done".loc() :
                    "next".loc()) {
              viewStore.send(.nextStep)
            }
            .padding(.horizontal, DesignConstants.paddingLarge)
            .frame(minWidth: DesignConstants.frameWidthXLarge,
                   minHeight: DesignConstants.frameHeightLarge)
            .background(ResourcesAsset.Colors.clam.swiftUIColor)
            .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
            .font(.body.weight(.semibold))
            .cornerRadius(DesignConstants.cornerRadiusMedium)
            .padding(DesignConstants.paddingLarge)
          }
          .padding(DesignConstants.paddingLarge)
        }
      }
    }
  }
}

#Preview {
  ZStack {
    BgWithGradientView()
    OnboardingView(store: .init(
      initialState: .init(),
      reducer: {
        Onboarding()
      }
    ))
  }
}
