import SwiftUI
import Resources
import Common

public struct RequestsHelpView: View {
  @Environment(\.dismiss) var dismiss
  
  public init() {}
  
  public var body: some View {
    ZStack {
      AuraBackground(level: .sacral)
      
      ScrollView {
        VStack(spacing: DesignConstants.spacingXLarge) {
          // Header
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Image(systemName: "questionmark.circle")
              .font(.system(size: DesignConstants.helpIconSize))
              .foregroundStyle(AuraGradient.gradient(for: .sacral))
            
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
          
          // Detailed process of working with the Lords of Karma
          VStack(spacing: DesignConstants.spacingLarge) {
            Text("karma_help_title".loc)
              .font(Typography.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .multilineTextAlignment(.center)
            
            VStack(spacing: DesignConstants.spacing) {
              karmaStep(
                number: 1,
                text: "karma_step_1".loc
              )
              
              karmaStep(
                number: 2,
                text: "karma_step_2".loc
              )
              
              karmaStep(
                number: 3,
                text: "karma_step_3".loc
              )
              
              karmaStep(
                number: 4,
                text: "karma_step_4".loc
              )
              
              // Liberation prayer
              VStack(alignment: .leading, spacing: DesignConstants.helpTipSpacing) {
                Text("karma_liberation_prayer".loc)
                  .font(Typography.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                  .multilineTextAlignment(.leading)
                  .italic()
              }
              .padding(.horizontal, DesignConstants.paddingMedium)
              .padding(.vertical, DesignConstants.paddingMedium)
              .cardStyle(level: .sacral, showsWatermark: false)
              
              karmaStep(
                number: 5,
                text: "karma_step_5".loc
              )
              
              karmaStep(
                number: 6,
                text: "karma_step_6".loc
              )
              
              karmaStep(
                number: 7,
                text: "karma_step_7".loc
              )
              
              karmaStep(
                number: 8,
                text: "karma_step_8".loc
              )
              
              // Categories of karmic healing
              VStack(alignment: .leading, spacing: DesignConstants.helpTipSpacing) {
                Text("karma_category_a".loc)
                  .font(Typography.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                
                Text("karma_category_b".loc)
                  .font(Typography.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                
                Text("karma_category_c".loc)
                  .font(Typography.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                
                Text("karma_category_d".loc)
                  .font(Typography.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              }
              .padding(.horizontal, DesignConstants.paddingMedium)
              .padding(.vertical, DesignConstants.paddingMedium)
              .cardStyle(level: .sacral, showsWatermark: false)
              
              karmaStep(
                number: 9,
                text: "karma_step_9".loc
              )
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingLarge)
          .cardStyle(level: .sacral, showsWatermark: false)
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          // Request Structure
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Text("requests_structure_title".loc)
              .font(Typography.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            
            VStack(spacing: DesignConstants.helpTipSpacing) {
              tipRow(text: "requests_structure_explanation".loc)
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingLarge)
          .cardStyle(level: .sacral, showsWatermark: false)
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          // Important tips
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Text("help_tips_title".loc)
              .font(Typography.title)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            
            VStack(spacing: DesignConstants.helpTipSpacing) {
              tipRow(text: "help_tip_1".loc)
              tipRow(text: "help_tip_2".loc)
              tipRow(text: "help_tip_3".loc)
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingLarge)
          .cardStyle(level: .sacral, showsWatermark: false)
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
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .renderingMode(.template)
              .foregroundStyle(AuraGradient.gradient(for: .sacral))
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
          .stroke(AuraGradient.gradient(for: .sacral), lineWidth: DesignConstants.lineWidth)
          .frame(width: DesignConstants.helpStepCircleSize, height: DesignConstants.helpStepCircleSize)
        
        Text("\(number)")
          .font(Typography.title)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      }
      
      VStack(alignment: .leading, spacing: DesignConstants.helpTipSpacing) {
        HStack {
          Image(systemName: icon)
            .foregroundStyle(AuraGradient.gradient(for: .sacral))
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
    .cardStyle(level: .sacral, showsWatermark: false)
  }
  
  private func karmaStep(number: Int, text: String) -> some View {
    HStack(alignment: .top, spacing: DesignConstants.helpStepSpacing) {
      // Step number
      ZStack {
        Circle()
          .stroke(AuraGradient.gradient(for: .sacral), lineWidth: DesignConstants.lineWidth)
          .frame(width: DesignConstants.helpStepCircleSizeSmall, height: DesignConstants.helpStepCircleSizeSmall)
        
        Text("\(number)")
          .font(Typography.caption.weight(.bold))
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      }
      
      Text(text)
        .font(Typography.body)
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .multilineTextAlignment(.leading)
      
      Spacer()
    }
  }
  
  private func tipRow(text: String) -> some View {
    HStack(alignment: .top, spacing: DesignConstants.helpTipSpacing) {
      Image(systemName: "lightbulb")
        .foregroundStyle(AuraGradient.gradient(for: .sacral))
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
    RequestsHelpView()
  }
}
