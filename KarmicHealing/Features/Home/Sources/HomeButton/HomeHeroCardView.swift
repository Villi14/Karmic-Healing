//
// Karmic Healing 2025
//

import SwiftUI
import Resources
import Common

public struct HomeHeroCardView: View {
  private let action: () -> Void

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(alignment: .top, spacing: DesignConstants.spacingLarge) {
        ZStack {
          Circle()
            .fill(AuraGradient.soft(for: .heart))
            .frame(width: DesignConstants.frameHeightXXLarge, height: DesignConstants.frameHeightXXLarge)

          Image(systemName: "apple.meditate")
            .font(.system(size: DesignConstants.frameHeightMedium, weight: .light))
            .foregroundStyle(AuraGradient.gradient(for: .heart))
        }

        VStack(alignment: .leading, spacing: DesignConstants.spacingSmall) {
          Text("home_daily_eyebrow".loc)
            .karmicLabel(tone: Spectrum.heart.color)

          Text("home_daily_title".loc)
            .font(Typography.heading)
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            .multilineTextAlignment(.leading)

          Text("home_daily_subtitle".loc)
            .font(Typography.bodySecondary)
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
            .fixedSize(horizontal: false, vertical: true)

          Label("start_session".loc, systemImage: "arrow.right")
            .font(Typography.body.weight(.semibold))
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(ResourcesAsset.Colors.onAccent.swiftUIColor)
            .padding(.horizontal, DesignConstants.paddingLarge)
            .padding(.vertical, DesignConstants.paddingMedium)
            .background(AuraGradient.gradient(for: .heart), in: Capsule())
            .padding(.top, DesignConstants.paddingSmall)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(DesignConstants.compact(DesignConstants.paddingXLarge, DesignConstants.paddingLarge))
      .cardStyle(level: .heart, showsWatermark: true)
    }
    .buttonStyle(.plain)
    .accessibilityHint("start_session_hint".loc)
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .heart)
    HomeHeroCardView {}
      .padding()
  }
}
