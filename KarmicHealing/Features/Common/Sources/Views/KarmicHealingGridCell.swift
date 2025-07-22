// Karmic Healing 2025

import SwiftUI
import Resources

public struct KarmicHealingGridCell: View {
  let color: Color
  let count: Int?
  let iconName: String
  let title: String
  let action: () -> Void

  public init(
    color: Color,
    count: Int? = nil,
    iconName: String,
    title: String,
    action: @escaping () -> Void
  ) {
    self.color = color
    self.count = count
    self.iconName = iconName
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: DesignConstants.spacingSmall) {

          Image(systemName: iconName)
            .resizable()
            .foregroundStyle(color)
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .padding(.top, DesignConstants.paddingSmall)

          Text(title)
            .font(.footnote.weight(.medium))
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            .padding(.top, DesignConstants.paddingSmall)
        }

        Spacer()

        if let count {
          Text("\(count)")
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        }
      }
      .padding(EdgeInsets(
        top: DesignConstants.padding,
        leading: DesignConstants.paddingLarge,
        bottom: DesignConstants.padding,
        trailing: DesignConstants.paddingLarge)
      )
      .background{
        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)

        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
          .inset(by: DesignConstants.lineWidthThin)
          .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(DesignConstants.opacityMedium),
                  lineWidth: DesignConstants.lineWidthThin)
      }
    }
  }
}
