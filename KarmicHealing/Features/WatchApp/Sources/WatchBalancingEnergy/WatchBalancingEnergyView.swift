//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI

public struct WatchBalancingEnergyView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @Bindable var store: StoreOf<WatchBalancingEnergy>
  @AppStorage("user_language") private var userLanguage: String = "en"

  public init(store: StoreOf<WatchBalancingEnergy>) {
    self.store = store
  }

  public var body: some View {
    NavigationStack {
      ZStack {
        KarmicHealingWatchAsset.Colors.background.swiftUIColor
          .ignoresSafeArea()

        if store.currentStep < store.steps.count {
          let step = store.steps[store.currentStep]

            VStack(spacing: DesignConstants.watchVStackSpacing) {
              // ScrollView without height restrictions
              ScrollView {
                VStack(spacing: DesignConstants.watchVStackSpacing) {
                  // Title - compact
                  Text(step.title.localized(for: Locale(identifier: userLanguage)))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(KarmicHealingWatchAsset.Colors.textPrimary.swiftUIColor)
                    .minimumScaleFactor(DesignConstants.watchMinimumScaleFactor)
                    .padding(.bottom, DesignConstants.watchTitleBottomPadding)

                  if !step.description.isEmpty {
                    Text(step.description.localized(for: Locale(identifier: userLanguage)))
                      .font(.subheadline)
                      .multilineTextAlignment(.center)
                      .foregroundColor(KarmicHealingWatchAsset.Colors.textSecondary.swiftUIColor)
                      .minimumScaleFactor(DesignConstants.watchMinimumScaleFactor)
                  }
                }
                .padding(.bottom, DesignConstants.watchScrollBottomPadding)
              }

              // Step indicator and navigation buttons on same line
              Group {
                if store.steps.count > 1 {
                  HStack {
                    // Previous button
                    Button(action: {
                      store.send(.previousStep)
                    }) {
                      Image(systemName: "chevron.left")
                        .font(.body)
                        .foregroundColor(KarmicHealingWatchAsset.Colors.friendly.swiftUIColor)
                        .padding(.horizontal, DesignConstants.watchButtonHorizontalPadding)
                        .padding(.vertical, DesignConstants.watchButtonVerticalPadding)
                    }
                    .disabled(store.currentStep == 0)
                    .opacity(store.currentStep == 0 ? DesignConstants.watchDisabledOpacity : DesignConstants.watchEnabledOpacity)
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text("\(store.currentStep + 1) / \(store.steps.count)")
                      .font(.caption2)
                      .foregroundColor(KarmicHealingWatchAsset.Colors.textSecondary.swiftUIColor)
                    
                    Spacer()
                    
                    // Next button
                    Button(action: {
                      store.send(.nextStep)
                    }) {
                      Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(KarmicHealingWatchAsset.Colors.friendly.swiftUIColor)
                        .padding(.horizontal, DesignConstants.watchButtonHorizontalPadding)
                        .padding(.vertical, DesignConstants.watchButtonVerticalPadding)
                    }
                    .disabled(store.currentStep == store.steps.count - 1)
                    .opacity(store.currentStep == store.steps.count - 1 ? DesignConstants.watchDisabledOpacity : DesignConstants.watchEnabledOpacity)
                    .buttonStyle(PlainButtonStyle())
                  }
                  .padding(.horizontal, DesignConstants.watchNavigationHorizontalPadding)
                } else {
                  Text("\(store.currentStep + 1) / \(store.steps.count)")
                    .font(.caption2)
                    .foregroundColor(KarmicHealingWatchAsset.Colors.textSecondary.swiftUIColor)
                }
              }
              .padding(.top, DesignConstants.watchNavigationTopPadding)
            }
            .gesture(
              DragGesture()
                .onEnded { value in
                  // Swipe left to go to next step
                  if value.translation.width < -DesignConstants.watchSwipeThreshold {
                    store.send(.nextStep)
                  }
                  // Swipe right to go to previous step
                  else if value.translation.width > DesignConstants.watchSwipeThreshold {
                    store.send(.previousStep)
                  }
                }
            )
          }
        }
      }
        .onAppear {
          store.send(.onAppear)
        }
        .onDisappear {
          store.send(.onDisappear)
        }
  }
}

#Preview {
  @Previewable @AppStorage("user_language") var userLanguage: String = "en"

  WatchBalancingEnergyView(store: .init(
    initialState: .init(
      title: "essential_self".localized(for: Locale(identifier: userLanguage)),
      currentStep: 0,
      isCompleted: false,
      steps: Step.part2
    ),
    reducer: {
      WatchBalancingEnergy()
    }
  ))
}
