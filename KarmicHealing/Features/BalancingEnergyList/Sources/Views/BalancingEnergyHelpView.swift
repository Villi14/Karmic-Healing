import SwiftUI
import Resources
import Common
import ComposableArchitecture

public struct BalancingEnergyHelpView: View {
  @Bindable var store: StoreOf<BalancingEnergyHelp>
  
  public init(store: StoreOf<BalancingEnergyHelp>) {
    self.store = store
  }
  
  public var body: some View {
    ZStack {
      AuraBackground(level: .heart)
      
      ScrollView {
        VStack(spacing: DesignConstants.spacingXLarge) {
          // Header
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Image(systemName: "questionmark.circle")
              .font(.system(size: DesignConstants.helpIconSize))
              .foregroundStyle(AuraGradient.gradient(for: .heart))
            
            Text("help_title".loc)
              .font(Typography.heading)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
            
            Text("help_subtitle".loc)
              .font(Typography.body)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .padding(.top, DesignConstants.paddingXLarge)

          // Main steps
          VStack(spacing: DesignConstants.spacingLarge) {
            helpStep(
              number: 1,
              title: "help_step_1_title".loc,
              description: "help_step_1_description".loc,
              icon: "heart"
            )
            
            helpStep(
              number: 2,
              title: "help_step_2_title".loc,
              description: "help_step_2_description".loc,
              icon: "moon.stars"
            )
            
            helpStep(
              number: 3,
              title: "help_step_3_title".loc,
              description: "help_step_3_description".loc,
              icon: "sun.max"
            )
            
            helpStep(
              number: 4,
              title: "help_step_4_title".loc,
              description: "help_step_4_description".loc,
              icon: "hand.raised"
            )
            
            helpStep(
              number: 5,
              title: "help_step_5_title".loc,
              description: "help_step_5_description".loc,
              icon: "checkmark.circle"
            )
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          // Meditation Settings
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Text("meditation_settings_title".loc)
              .font(Typography.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            
            VStack(spacing: DesignConstants.helpTipSpacing) {
              tipRow(text: "meditation_auto_scroll".loc)
              tipRow(text: "meditation_step_timing".loc)
              tipRow(text: "meditation_vibration_setting".loc)
              tipRow(text: "meditation_sound_setting".loc)
              tipRow(text: "meditation_volume_setting".loc)
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingLarge)
          .cardStyle(level: .heart, showsWatermark: false)
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          // Important tips
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Text("help_tips_title".loc)
              .font(Typography.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            
            VStack(spacing: DesignConstants.helpTipSpacing) {
              tipRow(text: "help_tip_initial_process".loc)
              tipRow(text: "help_tip_1".loc)
              tipRow(text: "help_tip_2".loc)
              tipRow(text: "help_tip_3".loc)
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingLarge)
          .cardStyle(level: .heart, showsWatermark: false)
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          Spacer(minLength: DesignConstants.spacingXLarge)
        }
        .karmicContentWidth()
      }
      .navigationTitle("help".loc)
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { store.send(.dismissButtonTapped) }) {
            Image(systemName: "xmark")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .heart))
          }
        }
      }
    }
  }
  
  private func helpStep(number: Int, title: String, description: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: DesignConstants.helpStepSpacing) {
      // Step number
      ZStack {
        Circle()
          .stroke(AuraGradient.gradient(for: .heart), lineWidth: DesignConstants.lineWidth)
          .frame(width: DesignConstants.helpStepCircleSize, height: DesignConstants.helpStepCircleSize)
        
        Text("\(number)")
          .font(Typography.title)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      }
      
      VStack(alignment: .leading, spacing: DesignConstants.helpTipSpacing) {
        HStack {
          Image(systemName: icon)
            .foregroundStyle(AuraGradient.gradient(for: .heart))
            .font(Typography.icon)
          
          Text(title)
            .font(Typography.title)
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        }
        
        Text(description)
          .font(Typography.body)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .multilineTextAlignment(.leading)
      }
      
      Spacer()
    }
    .padding(.horizontal, DesignConstants.paddingMedium)
    .padding(.vertical, DesignConstants.paddingMedium)
    .cardStyle(level: .heart, showsWatermark: false)
  }
  
  private func tipRow(text: String) -> some View {
    HStack(alignment: .top, spacing: DesignConstants.helpTipSpacing) {
      Image(systemName: "lightbulb")
        .foregroundStyle(AuraGradient.gradient(for: .heart))
        .font(Typography.icon)
      
      Text(text)
        .font(Typography.body)
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .multilineTextAlignment(.leading)
      
      Spacer()
    }
  }
}

#Preview {
  NavigationStack {
    BalancingEnergyHelpView(
      store: Store(initialState: BalancingEnergyHelp.State()) {
        BalancingEnergyHelp()
      }
    )
  }
}
