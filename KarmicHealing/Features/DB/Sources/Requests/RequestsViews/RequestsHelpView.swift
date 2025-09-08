import SwiftUI
import Resources
import Common

public struct RequestsHelpView: View {
  @Environment(\.dismiss) var dismiss
  
  public init() {}
  
  public var body: some View {
    ZStack {
      BgWithGradientView()
      
      ScrollView {
        VStack(spacing: DesignConstants.spacingXLarge) {
          // Header
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Image(systemName: "questionmark.circle")
              .font(.system(size: DesignConstants.helpIconSize))
              .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
            
            Text("help_title".loc())
              .font(.title.weight(.bold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .multilineTextAlignment(.center)
              .padding(.horizontal)

            Text("help_subtitle".loc())
              .font(.body)
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .padding(.top, DesignConstants.paddingXLarge)
          
          // Main steps
          VStack(spacing: DesignConstants.spacingLarge) {
            helpStep(
              number: 1,
              title: "help_step_1_title".loc(),
              description: "help_step_1_description".loc(),
              icon: "heart"
            )
            
            helpStep(
              number: 2,
              title: "help_step_2_title".loc(),
              description: "help_step_2_description".loc(),
              icon: "moon.stars"
            )
            
            helpStep(
              number: 3,
              title: "help_step_3_title".loc(),
              description: "help_step_3_description".loc(),
              icon: "sun.max"
            )
            
            helpStep(
              number: 4,
              title: "help_step_4_title".loc(),
              description: "help_step_4_description".loc(),
              icon: "hand.raised"
            )
            
            helpStep(
              number: 5,
              title: "help_step_5_title".loc(),
              description: "help_step_5_description".loc(),
              icon: "checkmark.circle"
            )
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          // Detailed process of working with the Lords of Karma
          VStack(spacing: DesignConstants.spacingLarge) {
            Text("karma_help_title".loc())
              .font(.headline.weight(.semibold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
              .multilineTextAlignment(.center)
            
            VStack(spacing: DesignConstants.spacing) {
              karmaStep(
                number: 1,
                text: "karma_step_1".loc()
              )
              
              karmaStep(
                number: 2,
                text: "karma_step_2".loc()
              )
              
              karmaStep(
                number: 3,
                text: "karma_step_3".loc()
              )
              
              karmaStep(
                number: 4,
                text: "karma_step_4".loc()
              )
              
              // Liberation prayer
              VStack(alignment: .leading, spacing: DesignConstants.helpTipSpacing) {
                Text("karma_liberation_prayer".loc())
                  .font(.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                  .multilineTextAlignment(.leading)
                  .italic()
              }
              .padding(.horizontal, DesignConstants.paddingMedium)
              .padding(.vertical, DesignConstants.paddingMedium)
              .background(
                RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
                  .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
                  .opacity(0.7)
              )
              
              karmaStep(
                number: 5,
                text: "karma_step_5".loc()
              )
              
              karmaStep(
                number: 6,
                text: "karma_step_6".loc()
              )
              
              karmaStep(
                number: 7,
                text: "karma_step_7".loc()
              )
              
              karmaStep(
                number: 8,
                text: "karma_step_8".loc()
              )
              
              // Categories of karmic healing
              VStack(alignment: .leading, spacing: DesignConstants.helpTipSpacing) {
                Text("karma_category_a".loc())
                  .font(.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                
                Text("karma_category_b".loc())
                  .font(.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                
                Text("karma_category_c".loc())
                  .font(.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                
                Text("karma_category_d".loc())
                  .font(.body)
                  .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
              }
              .padding(.horizontal, DesignConstants.paddingMedium)
              .padding(.vertical, DesignConstants.paddingMedium)
              .background(
                RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
                  .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
                  .opacity(0.7)
              )
              
              karmaStep(
                number: 9,
                text: "karma_step_9".loc()
              )
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingLarge)
          .background(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
              .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
          )
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          // Important tips
          VStack(spacing: DesignConstants.helpStepSpacing) {
            Text("help_tips_title".loc())
              .font(.headline.weight(.semibold))
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            
            VStack(spacing: DesignConstants.helpTipSpacing) {
              tipRow(text: "help_tip_1".loc())
              tipRow(text: "help_tip_2".loc())
              tipRow(text: "help_tip_3".loc())
              tipRow(text: "help_tip_4".loc())
            }
          }
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.vertical, DesignConstants.paddingLarge)
          .background(
            RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
              .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
          )
          .padding(.horizontal, DesignConstants.paddingLarge)
          
          Spacer(minLength: DesignConstants.spacingXLarge)
        }
      }
      .navigationTitle("help".loc())
      .navigationBarTitleDisplayMode(.inline)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbarBackground(ResourcesAsset.Colors.background.swiftUIColor, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
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
          .stroke(ResourcesAsset.Colors.clam.swiftUIColor, lineWidth: DesignConstants.lineWidth)
          .frame(width: DesignConstants.helpStepCircleSize, height: DesignConstants.helpStepCircleSize)
        
        Text("\(number)")
          .font(.headline.weight(.bold))
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      }
      
      VStack(alignment: .leading, spacing: DesignConstants.helpTipSpacing) {
        HStack {
          Image(systemName: icon)
            .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
            .font(.title3)
          
          Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        }
        
        Text(description)
          .font(.body)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .multilineTextAlignment(.leading)
      }
      
      Spacer()
    }
    .padding(.horizontal, DesignConstants.paddingMedium)
    .padding(.vertical, DesignConstants.paddingMedium)
    .background(
      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
        .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
    )
  }
  
  private func karmaStep(number: Int, text: String) -> some View {
    HStack(alignment: .top, spacing: DesignConstants.helpStepSpacing) {
      // Step number
      ZStack {
        Circle()
          .stroke(ResourcesAsset.Colors.clam.swiftUIColor, lineWidth: DesignConstants.lineWidth)
          .frame(width: DesignConstants.helpStepCircleSizeSmall, height: DesignConstants.helpStepCircleSizeSmall)
        
        Text("\(number)")
          .font(.caption.weight(.bold))
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      }
      
      Text(text)
        .font(.body)
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .multilineTextAlignment(.leading)
      
      Spacer()
    }
  }
  
  private func tipRow(text: String) -> some View {
    HStack(alignment: .top, spacing: DesignConstants.helpTipSpacing) {
      Image(systemName: "lightbulb")
        .foregroundStyle(ResourcesAsset.Colors.friendly.swiftUIColor)
        .font(.title3)
      
      Text(text)
        .font(.body)
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
