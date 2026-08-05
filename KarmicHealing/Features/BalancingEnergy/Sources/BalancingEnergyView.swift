//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct BalancingEnergyView: View {
  @SwiftUI.Environment(\.scenePhase) var scenePhase

  @Bindable public var store: StoreOf<BalancingEnergy>

  public init(store: StoreOf<BalancingEnergy>) {
    self.store = store
  }

  public var body: some View {
    let currentProgress = progress(of: store.currentStep, in: store.steps.count)
    let currentLevel = Spectrum.level(at: currentProgress)
    let currentGradient = AuraGradient.gradient(for: currentLevel)

    ZStack {
        AuraBackground(tone: tone(for: store))

        VStack {
          Text("attention_before_proceeding".loc)
            .karmicLabel()
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, DesignConstants.paddingXLarge)
            .padding(.top, DesignConstants.paddingLarge)

          HStack(alignment: .center, spacing: DesignConstants.spacingMedium) {
            StepLadder(
              count: store.steps.count,
              currentStep: store.currentStep,
              gradient: currentGradient
            )
            .padding(.leading, DesignConstants.paddingLarge)

            // The page binding is the only swipe handler: a second DragGesture on top of it used to
            // let one swipe count twice and skip a slide.
            TabView(selection: Binding(
              get: { store.currentStep },
              set: { newValue in
                if newValue > store.currentStep {
                  store.send(.nextStep)
                } else if newValue < store.currentStep {
                  store.send(.previousStep)
                }
              }
            )) {
              ForEach(Array(store.steps.enumerated()), id: \.offset) { index, step in
                let stepProgress = progress(of: index, in: store.steps.count)
                let stepTone = Spectrum.tone(at: stepProgress)
                let stepLevel = Spectrum.level(at: stepProgress)
                let stepGradient = AuraGradient.gradient(for: stepLevel)
                let stepCounter = "step_counter".loc(index + 1, store.steps.count)

                VStack(alignment: .leading, spacing: DesignConstants.spacingMedium) {
                  Text(stepCounter)
                    .karmicLabel(tone: stepTone)

                  BreathingRings(
                    tone: stepTone,
                    gradient: stepGradient
                  )
                    .frame(width: DesignConstants.breathingRingSize, height: DesignConstants.breathingRingSize)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignConstants.padding)

                  Text(step.title)
                    .font(Typography.title)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
                    .minimumScaleFactor(0.5)

                  Text(step.description)
                    .font(Typography.bodySecondary)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                    .minimumScaleFactor(0.5)

                  Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignConstants.paddingXLarge)
                .tag(index)
                .cardStyle(
                  tone: tone(for: store),
                  gradient: AuraGradient.gradient(for: level(for: store))
                )
                // Half the gap on each page, so neighbouring cards keep a full
                // one between them while the swipe is in flight.
                .padding(.horizontal, DesignConstants.padding)
                .padding(.bottom, DesignConstants.bottomPaddingLarge)
              }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.trailing, DesignConstants.paddingLarge)
          }
          // On iPad the step would otherwise stretch across the whole pane and the
          // ladder would sit an arm's length from the text it belongs to.
          .karmicContentWidth()

          if !store.isLastStep {
            AutoAdvanceBadge(
              store: store,
              gradient: currentGradient,
              tone: tone(for: store)
            )
            .padding(.bottom, DesignConstants.padding)
          }

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

            // Finishing leaves the screen too, but the session does that itself once it has
            // stored what it has to store.
            Button(store.isLastStep ? "done".loc : "next".loc) {
              store.send(store.isLastStep ? .completeSteps : .nextStep)
            }
            .buttonStyle(.karmic(
              tone: tone(for: store),
              gradient: AuraGradient.gradient(for: level(for: store))
            ))
          }
          .padding(.horizontal, DesignConstants.paddingXLarge)
          .padding(.bottom, DesignConstants.paddingLarge)
          .karmicContentWidth()
        }

        // The display is really dimmed to zero underneath; this covers what the panel still leaks
        // and gives the touch target that brings the step back.
        if store.isResting {
          Color.black
            .ignoresSafeArea()
            .transition(.opacity)
            .onTapGesture { store.send(.screenTapped) }
            .accessibilityLabel("screen_rest".loc)
            .accessibilityAddTraits(.isButton)
        }
      }
      // Resting keeps the display awake behind an opaque black cover, so nothing underneath is
      // worth a frame. This is the one screen that stays lit for an hour at a time; left running,
      // the hidden mesh gradient is the single largest draw on the battery in a whole session.
      .environment(\.auraMotionPaused, store.isResting)
      .animation(Motion.screenFade, value: store.isResting)
      .navigationTitle(store.title)
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .onAppear { store.send(.onAppear) }
      .onChange(of: scenePhase) { _, phase in
        // Backgrounding is not the end of a session, but it does stop it: nothing runs while the
        // app is out of sight, and coming back resumes from the same slide.
        switch phase {
        case .active: store.send(.didBecomeActive)
        case .background, .inactive: store.send(.didEnterBackground)
        @unknown default: break
        }
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { store.send(.dismissTapped) }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .heart))
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { store.send(.didTapSettings) }) {
            Image(systemName: "gearshape")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .heart))
          }
        }
      }
    .fullScreenCover(item: $store.scope(\.destination?.settings, action: \.destination.settings)) { settingsStore in
        EnergyBalansingSettingsView(store: settingsStore)
      }
  }

  /// How far up the spectrum the session has climbed, 0…1.
  private func progress(of step: Int, in count: Int) -> Double {
    guard count > 1 else { return 0 }
    return Double(step) / Double(count - 1)
  }

  private func tone(for store: StoreOf<BalancingEnergy>) -> Color {
    Spectrum.tone(at: progress(of: store.currentStep, in: store.steps.count))
  }

  private func level(for store: StoreOf<BalancingEnergy>) -> Spectrum {
    Spectrum.level(at: progress(of: store.currentStep, in: store.steps.count))
  }
}

/// Tells the user *when* the slide will turn, and lets them hold it.
///
/// The screen used to change on its own with no warning at all, which reads as a glitch rather
/// than as a guided pace.
private struct AutoAdvanceBadge: View {
  let store: StoreOf<BalancingEnergy>
  let gradient: LinearGradient
  let tone: Color

  var body: some View {
    let isPaused = store.isPaused

    HStack(spacing: DesignConstants.spacingSmall) {
        ZStack {
          Circle()
            .stroke(gradient.opacity(DesignConstants.opacityMedium), lineWidth: DesignConstants.lineWidthThin)
          Circle()
            .trim(from: 0, to: isPaused ? 1 : store.stepProgress)
            .stroke(gradient, style: StrokeStyle(lineWidth: DesignConstants.lineWidthThin, lineCap: .round))
            .rotationEffect(.degrees(-90))
        }
        .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)

        Text(isPaused ? "paused".loc : "next_step_in".loc(formatted(store.remaining)))
          .karmicLabel(tone: tone)

        Button(action: { store.send(.pauseToggled) }) {
          Image(systemName: isPaused ? "play.fill" : "pause.fill")
            .renderingMode(.template)
            .font(Typography.icon)
            .foregroundStyle(gradient)
        }
        .accessibilityLabel(isPaused ? "resume".loc : "pause".loc)
      }
      .padding(.horizontal, DesignConstants.paddingLarge)
      .padding(.vertical, DesignConstants.paddingSmall)
      .animation(Motion.touch, value: isPaused)
  }

  private func formatted(_ remaining: TimeInterval) -> String {
    let total = Int(remaining.rounded(.up))
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}

/// Session progress as a rising ladder, root at the bottom, crown at the top.
private struct StepLadder: View {
  let count: Int
  let currentStep: Int
  let gradient: LinearGradient

  var body: some View {
    VStack(spacing: DesignConstants.spacingSmall) {
      ForEach((0..<count).reversed(), id: \.self) { index in
        let isReached = index <= currentStep
        Circle()
          .fill(isReached ? AnyShapeStyle(gradient) : AnyShapeStyle(.clear))
          .stroke(gradient.opacity(isReached ? 1 : DesignConstants.opacityMedium),
                  lineWidth: DesignConstants.lineWidthThin * 2)
          .frame(width: DesignConstants.rungSize, height: DesignConstants.rungSize)
          .overlay {
            if index == currentStep {
              Circle()
                .stroke(AuraGradient.soft(for: .heart),
                        lineWidth: DesignConstants.rungHaloWidth)
            }
          }
      }
    }
    .animation(Motion.touch, value: currentStep)
    .accessibilityHidden(true)
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .heart)
    BalancingEnergyView(store: .init(
      initialState: .init(
        kind: .initialProcess,
        title: "initial_process".loc,
        currentStep: 0,
        isCompleted: false,
        steps: Step.part1
      ),
      reducer: {
        BalancingEnergy()
      }
    ))
  }
}
