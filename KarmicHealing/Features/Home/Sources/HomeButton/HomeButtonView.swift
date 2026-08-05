//
// Karmic Healing 2025
//

import SwiftUI
import Resources
import Common

public struct HomeButtonView: View {
  let homeButton: HomeButton

  public init(homeButton: HomeButton) {
    self.homeButton = homeButton
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: DesignConstants.spacingSmall) {
      HStack(alignment: .top) {
        homeButton.icon
          .resizable()
          .foregroundStyle(AuraGradient.gradient(for: homeButton.level))
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: DesignConstants.maxWidthSmall)

        Spacer()

        Circle()
          .fill(AuraGradient.gradient(for: homeButton.level))
          .frame(width: DesignConstants.frameWidthSmall, height: DesignConstants.frameWidthSmall)
      }

      Spacer(minLength: DesignConstants.padding)

        Text(homeButton.title)
          .font(Typography.cardTitle)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          .multilineTextAlignment(.leading)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
    }
    .padding(DesignConstants.paddingLarge)
    .frame(maxWidth: .infinity, alignment: .leading)
    .aspectRatio(DesignConstants.cardAspectRatio, contentMode: .fit)
    .cardStyle(level: homeButton.level)
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .heart)

    HomeButtonView(homeButton: .balancingEnergyButton)
      .frame(width: DesignConstants.maxWidthMedium / 2)
  }
}
