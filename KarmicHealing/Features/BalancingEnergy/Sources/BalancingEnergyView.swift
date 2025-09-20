//
// Karmic Healing 2025
//

import ComposableArchitecture
import SwiftUI
import Resources
import Common
import UserNotifications

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
            .minimumScaleFactor(0.5)
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
                    .minimumScaleFactor(0.5)
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
                print("BalancingEnergyView: Done button tapped - completing steps")
                viewStore.send(.completeSteps)
                
                // Cancel notifications immediately when done
                let notificationCenter = UNUserNotificationCenter.current()
                notificationCenter.getPendingNotificationRequests { requests in
                  let balancingEnergyIdentifiers = requests.compactMap { request in
                    let userInfo = request.content.userInfo
                    if let notificationType = userInfo["notificationType"] as? String,
                       notificationType == "BALANCING_ENERGY" {
                      return request.identifier
                    }
                    return nil
                  }
                  
                  if !balancingEnergyIdentifiers.isEmpty {
                    notificationCenter.removePendingNotificationRequests(withIdentifiers: balancingEnergyIdentifiers)
                    print("BalancingEnergyView: Done button - cancelled \(balancingEnergyIdentifiers.count) balancing energy notifications")
                  }
                }
                
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
        print("BalancingEnergyView: onDisappear called")
        print("BalancingEnergyView: Sending .onDisappear action")
        viewStore.send(.onDisappear)
        
        // Also cancel notifications directly as backup
        print("BalancingEnergyView: Cancelling notifications directly as backup")
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.getPendingNotificationRequests { requests in
          let balancingEnergyIdentifiers = requests.compactMap { request in
            let userInfo = request.content.userInfo
            if let notificationType = userInfo["notificationType"] as? String,
               notificationType == "BALANCING_ENERGY" {
              return request.identifier
            }
            return nil
          }
          
          if !balancingEnergyIdentifiers.isEmpty {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: balancingEnergyIdentifiers)
            print("BalancingEnergyView: Directly cancelled \(balancingEnergyIdentifiers.count) balancing energy notifications")
            print("BalancingEnergyView: Cancelled identifiers: \(balancingEnergyIdentifiers)")
          } else {
            print("BalancingEnergyView: No balancing energy notifications found to cancel directly")
          }
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
        viewStore.send(.settingsDidChange)
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { 
            print("BalancingEnergyView: Back button tapped")
            
            // Cancel notifications immediately when going back
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.getPendingNotificationRequests { requests in
              let balancingEnergyIdentifiers = requests.compactMap { request in
                let userInfo = request.content.userInfo
                if let notificationType = userInfo["notificationType"] as? String,
                   notificationType == "BALANCING_ENERGY" {
                  return request.identifier
                }
                return nil
              }
              
              if !balancingEnergyIdentifiers.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: balancingEnergyIdentifiers)
                print("BalancingEnergyView: Back button - cancelled \(balancingEnergyIdentifiers.count) balancing energy notifications")
              }
            }
            
            dismiss() 
          }) {
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


