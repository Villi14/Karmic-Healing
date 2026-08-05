// Karmic Healing 2025

import SwiftUI
import Resources

public struct GridCell: View {
  let color: Color
  let count: Int?
  let iconName: String
  let title: String
  let level: Spectrum
  let action: () -> Void

  public init(
    color: Color,
    count: Int? = nil,
    iconName: String,
    title: String,
    level: Spectrum = .solar,
    action: @escaping () -> Void
  ) {
    self.color = color
    self.count = count
    self.iconName = iconName
    self.title = title
    self.level = level
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: DesignConstants.spacingSmall) {

          Image(systemName: iconName)
            .resizable()
            .foregroundStyle(AuraGradient.gradient(for: level))
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .padding(.top, DesignConstants.paddingSmall)

          Text(title)
            .font(Typography.cardTitle)
            .minimumScaleFactor(0.5)
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            .padding(.top, DesignConstants.paddingSmall)
        }

        Spacer()

        if let count {
          Text("\(count)")
            .font(Typography.figure)
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        }
      }
      .padding(EdgeInsets(
        top: DesignConstants.padding,
        leading: DesignConstants.paddingLarge,
        bottom: DesignConstants.padding,
        trailing: DesignConstants.paddingLarge)
      )
      .cardStyle(level: level, showsWatermark: true)
    }
  }
}
