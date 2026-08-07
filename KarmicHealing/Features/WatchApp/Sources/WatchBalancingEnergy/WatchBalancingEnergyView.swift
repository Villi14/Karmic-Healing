//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI

public struct WatchBalancingEnergyView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @SwiftUI.Environment(\.scenePhase) var scenePhase
  @Bindable var store: StoreOf<WatchBalancingEnergy>
  @AppStorage("user_language") private var userLanguage: String = "en"

  public init(store: StoreOf<WatchBalancingEnergy>) {
    self.store = store
  }

  private var locale: Locale { Locale(identifier: userLanguage) }

  /// How far up the spectrum the session has climbed.
  private var tone: Color {
    guard store.steps.count > 1 else { return Spectrum.heart.color }
    return Spectrum.tone(at: Double(store.currentStep) / Double(store.steps.count - 1))
  }

  public var body: some View {
    NavigationStack {
      ZStack {
        KarmicHealingWatchAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()

        if store.currentStep < store.steps.count {
          let step = store.steps[store.currentStep]

          VStack(spacing: DesignConstants.watchVStackSpacing) {
            ScrollView {
              VStack(spacing: DesignConstants.watchVStackSpacing) {
                Text(step.title.localized(for: locale))
                  .font(Typography.title)
                  .multilineTextAlignment(.center)
                  .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
                  .minimumScaleFactor(DesignConstants.watchMinimumScaleFactor)
                  .padding(.bottom, DesignConstants.watchTitleBottomPadding)

                if !step.description.isEmpty {
                  Text(step.description.localized(for: locale))
                    .font(Typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(KarmicHealingWatchAsset.Colors.textSecondary.swiftUIColor)
                    .minimumScaleFactor(DesignConstants.watchMinimumScaleFactor)
                }
              }
              .padding(.bottom, DesignConstants.watchScrollBottomPadding)
            }

            if !store.isLastStep {
              AutoAdvanceBadge(
                remaining: store.remaining,
                progress: store.stepProgress,
                isPaused: store.isPaused,
                tone: tone,
                locale: locale
              ) {
                store.send(.pauseToggled)
              }
            }

            navigationRow
              .padding(.top, DesignConstants.watchNavigationTopPadding)
          }
          .gesture(
            DragGesture()
              .onEnded { value in
                if value.translation.width < -DesignConstants.watchSwipeThreshold {
                  store.send(.nextStep)
                } else if value.translation.width > DesignConstants.watchSwipeThreshold {
                  store.send(.previousStep)
                }
              }
          )
        }

      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { store.send(.didTapSettings) }) {
            Image(systemName: "gearshape")
              .foregroundColor(tone)
          }
        }
      }
    }
    .onAppear { store.send(.onAppear) }
    .onChange(of: scenePhase) { _, phase in
      // A dropped wrist must not disturb the session — see `forScenePhase`.
      if let action = WatchBalancingEnergy.Action.forScenePhase(phase) {
        store.send(action)
      }
    }
    .sheet(item: $store.scope(state: \.destination?.settings, action: \.destination.settings)) { settingsStore in
      WatchSettingsView(store: settingsStore)
    }
  }

  @ViewBuilder
  private var navigationRow: some View {
    Group {
      if store.steps.count > 1 {
        HStack {
          Button(action: { store.send(.previousStep) }) {
            Image(systemName: "chevron.left")
              .font(.body)
              .foregroundColor(tone)
              .padding(.horizontal, DesignConstants.watchButtonHorizontalPadding)
              .padding(.vertical, DesignConstants.watchButtonVerticalPadding)
          }
          .disabled(store.currentStep == 0)
          .opacity(store.currentStep == 0 ? DesignConstants.watchDisabledOpacity : DesignConstants.watchEnabledOpacity)
          .buttonStyle(PlainButtonStyle())

          Spacer()

          Text("\(store.currentStep + 1) / \(store.steps.count)")
            .font(Typography.label)
            .foregroundColor(tone)

          Spacer()

          Button(action: { store.send(.nextStep) }) {
            Image(systemName: "chevron.right")
              .font(.body)
              .foregroundColor(tone)
              .padding(.horizontal, DesignConstants.watchButtonHorizontalPadding)
              .padding(.vertical, DesignConstants.watchButtonVerticalPadding)
          }
          .disabled(store.isLastStep)
          .opacity(store.isLastStep ? DesignConstants.watchDisabledOpacity : DesignConstants.watchEnabledOpacity)
          .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, DesignConstants.watchNavigationHorizontalPadding)
      } else {
        Text("\(store.currentStep + 1) / \(store.steps.count)")
          .font(Typography.label)
          .foregroundColor(tone)
      }
    }
  }
}

/// Tells the user *when* the slide will turn, and lets them hold it.
private struct AutoAdvanceBadge: View {
  let remaining: TimeInterval
  let progress: Double
  let isPaused: Bool
  let tone: Color
  let locale: Locale
  let onToggle: () -> Void

  var body: some View {
    HStack(spacing: DesignConstants.paddingSmall) {
      ZStack {
        Circle()
          .stroke(tone.opacity(DesignConstants.watchDisabledOpacity), lineWidth: DesignConstants.watchRingLineWidth)
        Circle()
          .trim(from: 0, to: isPaused ? 1 : progress)
          .stroke(tone, style: StrokeStyle(lineWidth: DesignConstants.watchRingLineWidth, lineCap: .round))
          .rotationEffect(.degrees(-90))
      }
      .frame(width: DesignConstants.watchRingSize, height: DesignConstants.watchRingSize)

      Text(isPaused ? "paused".localized(for: locale) : formatted)
        .font(Typography.label)
        .foregroundColor(tone)

      Button(action: onToggle) {
        Image(systemName: isPaused ? "play.fill" : "pause.fill")
          .font(.footnote)
          .foregroundColor(tone)
      }
      .buttonStyle(PlainButtonStyle())
      .accessibilityLabel(isPaused ? "resume".localized(for: locale) : "pause".localized(for: locale))
    }
  }

  private var formatted: String {
    let total = Int(remaining.rounded(.up))
    return String(format: "%d:%02d", total / 60, total % 60)
  }
}

#Preview {
  WatchBalancingEnergyView(store: .init(
    initialState: WatchBalancingEnergy.State(
      title: "essential_self",
      currentStep: 0,
      isCompleted: false,
      steps: Step.part2
    ),
    reducer: {
      WatchBalancingEnergy()
    }
  ))
}
