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

  public var body: some View {
    ZStack {
        AuraBackground(tone: tone(for: store))
        mainContent(store: store)
      }
  }

  private func mainContent(store: StoreOf<Onboarding>) -> some View {
    VStack {
      skipButton(store: store)
      tabViewContent(store: store)
      bottomButtons(store: store)
    }
    .karmicContentWidth()
  }

  private func skipButton(store: StoreOf<Onboarding>) -> some View {
    HStack {
      Spacer()
      if store.steps.indices.contains(store.currentStep) && store.steps[store.currentStep].showSkipButton {
        Button("skip".loc) {
          store.send(.completeOnboarding)
        }
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .font(Typography.listTitle)
        .padding([.top, .trailing], DesignConstants.paddingLarge)
      } else {
        // Invisible spacer to maintain consistent height
        Text("skip".loc)
          .foregroundStyle(.clear)
          .font(Typography.listTitle)
          .padding([.top, .trailing], DesignConstants.paddingLarge)
      }
    }
    .frame(height: DesignConstants.onboardingSkipButtonHeight)
  }

  private func tabViewContent(store: StoreOf<Onboarding>) -> some View {
    TabView(selection: tabViewBinding(store: store)) {
      ForEach(Array(store.steps.enumerated()), id: \.offset) { index, step in
        onboardingStepView(
          step: step,
          tone: Spectrum.tone(at: progress(of: index, in: store.steps.count)),
          level: Spectrum.level(at: progress(of: index, in: store.steps.count))
        )
          .tag(index)
      }
    }
    .setTabViewdIndicatorColor
    .tabViewStyle(.page(indexDisplayMode: .always))
    .gesture(dragGesture(store: store))
  }

  private func tabViewBinding(store: StoreOf<Onboarding>) -> Binding<Int> {
    Binding(
      get: { store.currentStep },
      set: { newValue in
        if newValue > store.currentStep {
          store.send(.nextStep)
        } else if newValue < store.currentStep {
          store.send(.previousStep)
        }
      }
    )
  }

  private func onboardingStepView(step: OnboardingStep, tone: Color, level: Spectrum) -> some View {
    VStack(spacing: 0) {
      // Fixed height container for icon
      VStack {
        ZStack {
          Rings(count: 3)
            .stroke(AuraGradient.soft(for: level),
                    lineWidth: DesignConstants.lineWidthThin * 2)
            .frame(width: DesignConstants.watermarkSize, height: DesignConstants.watermarkSize)

          Image(systemName: step.imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.helpIconSize / 2)
            .foregroundStyle(AuraGradient.gradient(for: level))
        }
        .padding(DesignConstants.paddingLarge)
      }
      .frame(height: DesignConstants.onboardingIconContainerHeight)

      // Flexible text content
      VStack(spacing: DesignConstants.spacing) {
        Text(step.title)
          .font(Typography.heading)
          .multilineTextAlignment(.center)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          .padding(.horizontal, DesignConstants.paddingLarge)

        Text(step.description)
          .font(Typography.body)
          .multilineTextAlignment(.center)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .padding(.horizontal, DesignConstants.paddingLarge)
          .lineSpacing(DesignConstants.spacingSmall)
      }
      .padding(.top, DesignConstants.spacingLarge)
    }
  }

  /// The onboarding climbs the spectrum as it goes, like a session does.
  private func progress(of step: Int, in count: Int) -> Double {
    guard count > 1 else { return 0 }
    return Double(step) / Double(count - 1)
  }

  private func tone(for store: StoreOf<Onboarding>) -> Color {
    Spectrum.tone(at: progress(of: store.currentStep, in: store.steps.count))
  }

  private func level(for store: StoreOf<Onboarding>) -> Spectrum {
    Spectrum.level(at: progress(of: store.currentStep, in: store.steps.count))
  }

  private func dragGesture(store: StoreOf<Onboarding>) -> some Gesture {
    DragGesture()
      .onEnded { gesture in
        let threshold: CGFloat = DesignConstants.thresholdMedium
        if gesture.translation.width > threshold {
          if store.currentStep > 0 {
            store.send(.previousStep)
          }
        } else if gesture.translation.width < -threshold {
          if store.currentStep < store.steps.count - 1 {
            store.send(.nextStep)
          }
        }
      }
  }

  private func bottomButtons(store: StoreOf<Onboarding>) -> some View {
    HStack {
      if store.currentStep > 0 {
        Button("back".loc) {
          store.send(.previousStep)
        }
        .buttonStyle(.karmic(
          tone: tone(for: store),
          gradient: AuraGradient.gradient(for: level(for: store))
        ))
      }

      Spacer()

      Button(store.currentStep == store.steps.count - 1 ?
             "done".loc :
              "next".loc) {
        store.send(.nextStep)
      }
              .buttonStyle(.karmic(
                tone: tone(for: store),
                gradient: AuraGradient.gradient(for: level(for: store))
              ))
    }
    .padding(DesignConstants.paddingLarge)
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .root)
    OnboardingView(store: .init(
      initialState: .init(),
      reducer: {
        Onboarding()
      }
    ))
  }
}
