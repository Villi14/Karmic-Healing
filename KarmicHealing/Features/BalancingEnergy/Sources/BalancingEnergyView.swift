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
        LinearGradient(
          gradient: Gradient(colors: [
            ResourcesAsset.Colors.clam.swiftUIColor.opacity(0.1),
            ResourcesAsset.Colors.background.swiftUIColor
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
          Image(systemName: "exclamationmark.circle")
            .resizable()
            .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
            .aspectRatio(contentMode: .fit)
            .frame(height: 36)
            .padding(.top, 16)

          Text(String(localized: "attention_before_proceeding", bundle: .main))
            .font(.system(size: 16))
            .multilineTextAlignment(.center)
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
            .padding()

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
                Text(step.title)
                  .font(.system(size: 20, weight: .medium))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
                  .padding(.top, 24)
                  .padding(.horizontal)

                HStack {
                  Text(step.description)
                    .font(.system(size: 16, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                    .padding(.horizontal)

                  Spacer()
                }

                Spacer()
              }
              .tag(index)
              .background {
                Rectangle()
                  .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
                  .clipShape(RoundedRectangle(cornerRadius: 12))

                RoundedRectangle(cornerRadius: 12)
                  .inset(by: 0.5)
                  .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.5), lineWidth: 0.5)
              }
              .padding(.horizontal)
              .padding(.bottom, 50)
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
          .padding()

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
              if viewStore.currentStep == viewStore.steps.count - 1 {
                viewStore.send(.completeSteps)
                dismiss()
              } else {
                viewStore.send(.nextStep)
              }
            }
            .padding()
            .background(ResourcesAsset.Colors.clam.swiftUIColor)
            .foregroundStyle(ResourcesAsset.Colors.textInvert.swiftUIColor)
            .cornerRadius(12)
          }
          .padding()
        }
      }
      .navigationTitle(viewStore.title)
      .navigationBarBackButtonHidden(true)
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          }
        }
      }
    }
  }
}

#Preview {
  BalancingEnergyView(store: .init(
    initialState: .init(
      title: String(localized: "initial_process", bundle: .main),
      currentStep: 0,
      isCompleted: false,
      steps: Step.part1
    ),
    reducer: {
      BalancingEnergy()
    }
  ))
}


