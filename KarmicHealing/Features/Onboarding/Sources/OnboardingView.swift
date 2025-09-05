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
        mainContent(viewStore: viewStore)
      }
    }
  }

  private func mainContent(viewStore: ViewStore<ViewState, Onboarding.Action>) -> some View {
    VStack {
      skipButton(viewStore: viewStore)
      tabViewContent(viewStore: viewStore)
      bottomButtons(viewStore: viewStore)
    }
  }

  private func skipButton(viewStore: ViewStore<ViewState, Onboarding.Action>) -> some View {
    HStack {
      Spacer()
      if viewStore.steps.indices.contains(viewStore.currentStep) && viewStore.steps[viewStore.currentStep].showSkipButton {
        Button("skip".loc()) {
          viewStore.send(.completeOnboarding)
        }
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .font(.body.weight(.medium))
        .padding([.top, .trailing], DesignConstants.paddingLarge)
      } else {
        // Invisible spacer to maintain consistent height
        Text("skip".loc())
          .foregroundStyle(.clear)
          .font(.body.weight(.medium))
          .padding([.top, .trailing], DesignConstants.paddingLarge)
      }
    }
    .frame(height: DesignConstants.onboardingSkipButtonHeight)
  }

  private func tabViewContent(viewStore: ViewStore<ViewState, Onboarding.Action>) -> some View {
    TabView(selection: tabViewBinding(viewStore: viewStore)) {
      ForEach(Array(viewStore.steps.enumerated()), id: \.offset) { index, step in
        onboardingStepView(step: step)
          .tag(index)
      }
    }
    .setTabViewdIndicatorColor
    .tabViewStyle(.page(indexDisplayMode: .always))
    .gesture(dragGesture(viewStore: viewStore))
  }

  private func tabViewBinding(viewStore: ViewStore<ViewState, Onboarding.Action>) -> Binding<Int> {
    Binding(
      get: { viewStore.currentStep },
      set: { newValue in
        if newValue > viewStore.currentStep {
          viewStore.send(.nextStep)
        } else if newValue < viewStore.currentStep {
          viewStore.send(.previousStep)
        }
      }
    )
  }

  private func onboardingStepView(step: OnboardingStep) -> some View {
    VStack(spacing: 0) {
      // Fixed height container for icon
      VStack {
        Image(systemName: step.imageName)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.helpIconSize)
          .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
          .padding(DesignConstants.paddingLarge)
      }
      .frame(height: DesignConstants.onboardingIconContainerHeight)

      // Flexible text content
      VStack(spacing: DesignConstants.spacing) {
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
      .padding(.top, DesignConstants.spacingLarge)
    }
  }

  private func dragGesture(viewStore: ViewStore<ViewState, Onboarding.Action>) -> some Gesture {
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
  }

  private func bottomButtons(viewStore: ViewStore<ViewState, Onboarding.Action>) -> some View {
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
