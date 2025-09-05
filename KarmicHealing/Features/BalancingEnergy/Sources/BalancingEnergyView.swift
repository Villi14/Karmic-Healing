//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common

public struct BalancingEnergyView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss

  public let store: StoreOf<BalancingEnergy>

  public init(store: StoreOf<BalancingEnergy>) {
    self.store = store
  }

  private struct ViewState: Equatable {
    let title: String
    let currentStep: Int
    let steps: [Step]

    init(state: BalancingEnergy.State) {
      self.title = state.title
      self.currentStep = state.currentStep
      self.steps = state.steps
    }
  }

  public var body: some View {
    WithViewStore(store, observe: ViewState.init) { viewStore in
      ZStack {
        BgWithGradientView()

        VStack {
          Image(systemName: "exclamationmark.circle")
            .resizable()
            .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightMedium)
            .padding(.top, DesignConstants.paddingLarge)

          Text("attention_before_proceeding".loc())
            .font(.headline.weight(.medium))
            .multilineTextAlignment(.center)
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
            .padding()

          TabView(selection: Binding(
            get: { viewStore.currentStep },
            set: { newValue in
              if newValue > viewStore.currentStep {
                viewStore.send(.nextStep)
                viewStore.send(.userManuallyScrolled)
              } else if newValue < viewStore.currentStep {
                viewStore.send(.previousStep)
                viewStore.send(.userManuallyScrolled)
              }
            }
          )) {
            ForEach(Array(viewStore.steps.enumerated()), id: \.offset) { index, step in
              VStack(spacing: DesignConstants.spacingLarge) {
                Text(step.title)
                  .font(.body.weight(.medium))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
                  .padding(.top, DesignConstants.paddingXLarge)
                  .padding(.horizontal)

                HStack {
                  Text(step.description)
                    .font(.callout.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                    .padding(.horizontal)

                  Spacer()
                }
                .padding(.horizontal)

                Spacer()
              }
              .tag(index)
              .background {
                Rectangle()
                  .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
                  .clipShape(RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium))
              }
              .padding(.horizontal)
              .padding(.bottom, DesignConstants.bottomPaddingLarge)
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
                    viewStore.send(.userManuallyScrolled)
                  }
                } else if gesture.translation.width < -threshold {
                  if viewStore.currentStep < viewStore.steps.count - 1 {
                    viewStore.send(.nextStep)
                    viewStore.send(.userManuallyScrolled)
                  }
                }
              }
          )
          .padding()

          HStack {
            if viewStore.currentStep > 0 {
              Button("back".loc()) {
                viewStore.send(.previousStep)
                viewStore.send(.userManuallyScrolled)
              }
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .padding()
            }

            Spacer()

            Button(viewStore.currentStep == viewStore.steps.count - 1 ? "done".loc() : "next".loc()) {
              if viewStore.currentStep == viewStore.steps.count - 1 {
                viewStore.send(.completeSteps)
                dismiss()
              } else {
                viewStore.send(.nextStep)
                viewStore.send(.userManuallyScrolled)
              }
            }
            .padding(.horizontal, DesignConstants.paddingLarge)
            .frame(minWidth: DesignConstants.frameWidthXLarge,
                   minHeight: DesignConstants.frameHeightLarge)
            .background(ResourcesAsset.Colors.clam.swiftUIColor)
            .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
            .cornerRadius(DesignConstants.cornerRadiusMedium)
            .padding()
          }
          .padding()
        }
      }
      .navigationTitle(viewStore.title)
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .onAppear {
        viewStore.send(.onAppear)
      }
      .onDisappear {
        viewStore.send(.onDisappear)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { viewStore.send(.didTapSettings) }) {
            Image(systemName: "gearshape")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
          }
        }
      }
      .fullScreenCover(
        store: store.scope(
          state: \.$destination,
          action: \.destination
        ),
        state: \.settings,
        action: Destination.Action.settings
      ) { settingsStore in
        EnergyBalansingSettingsView(store: settingsStore)
      }
    }
  }
}

#Preview {
  ZStack {
    BgWithGradientView()
    BalancingEnergyView(store: .init(
      initialState: .init(
        title: "initial_process".loc(),
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


