//
// Karmic Healing 2025
//

import SwiftUI
import Resources

public struct KarmicEmptyStateView: View {
  private let iconName: String
  private let title: String
  private let message: String
  private let tone: Color
  private let level: Spectrum
  private let actionTitle: String?
  private let action: (() -> Void)?

  public init(
    iconName: String,
    title: String,
    message: String,
    tone: Color,
    level: Spectrum = .throat,
    actionTitle: String? = nil,
    action: (() -> Void)? = nil
  ) {
    self.iconName = iconName
    self.title = title
    self.message = message
    self.tone = tone
    self.level = level
    self.actionTitle = actionTitle
    self.action = action
  }

  public var body: some View {
    VStack(spacing: DesignConstants.spacing) {
      ZStack {
        Rings(count: 3)
          .stroke(AuraGradient.soft(for: level), lineWidth: DesignConstants.lineWidth)
          .frame(width: DesignConstants.watermarkSize, height: DesignConstants.watermarkSize)

        Image(systemName: iconName)
          .font(.system(size: DesignConstants.helpIconSize * 0.55, weight: .light))
          .foregroundStyle(AuraGradient.gradient(for: level))
      }
      .padding(.bottom, DesignConstants.paddingSmall)

      Text(title)
        .font(Typography.title)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.center)

      Text(message)
        .font(Typography.bodySecondary)
        .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)

      if let actionTitle, let action {
        Button(action: action) {
          Text(actionTitle)
        }
        .buttonStyle(.karmic(level: level))
        .padding(.top, DesignConstants.paddingSmall)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, DesignConstants.paddingXLarge)
    .padding(.vertical, DesignConstants.paddingXXLarge)
    .cardStyle(
      tone: tone,
      showsWatermark: true,
      gradient: AuraGradient.gradient(for: level)
    )
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .heart)
      KarmicEmptyStateView(
        iconName: "sparkles",
        title: "Nothing here yet",
        message: "Create your first item to begin.",
        tone: Spectrum.heart.color,
        level: .heart,
        actionTitle: "Create"
      ) {}
    .padding()
  }
}
