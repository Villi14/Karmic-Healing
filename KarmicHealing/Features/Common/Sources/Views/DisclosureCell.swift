//
// Karmic Healing 2025
//

import Resources
import SwiftUI

public struct DisclosureCell<Content: View>: View {
  private let content: () -> Content
  private let tone: SwiftUI.Color
  private let onTap: () -> Void

  public init(
    content: @escaping () -> Content,
    tone: SwiftUI.Color = Spectrum.throat.color,
    onTap: @escaping () -> Void
  ) {
    self.content = content
    self.tone = tone
    self.onTap = onTap
  }

  public var body: some View {
    Button(action: onTap) {
      HStack(spacing: DesignConstants.spacingMedium) {
        Rings(count: 2, innerRatio: 0.35)
          .stroke(AuraGradient.gradient(for: .throat), lineWidth: DesignConstants.lineWidthThin * 2)
          .frame(width: DesignConstants.frameHeightSmall, height: DesignConstants.frameHeightSmall)

        self.content()
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          .multilineTextAlignment(.leading)

        Spacer()

        Image(systemName: "chevron.right")
          .renderingMode(.template)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameWidthMedium)
          .foregroundStyle(AuraGradient.gradient(for: .throat))
      }
      .frame(maxWidth: .infinity, minHeight: DesignConstants.frameHeightXXLarge)
      .padding(.horizontal, DesignConstants.paddingLarge)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

public struct KarmicHealingDisclosureGroup<Content: View>: View {
  private let content: () -> Content
  private let tone: SwiftUI.Color

  public init(
    @ViewBuilder content: @escaping () -> Content,
    tone: SwiftUI.Color = Spectrum.throat.color
  ) {
    self.content = content
    self.tone = tone
  }

  public var body: some View {
    self.content()
      .cardStyle(tone: tone, showsWatermark: true)
  }
}

extension DisclosureCell where Content == Text {
  public init(_ title: String, tone: SwiftUI.Color = Spectrum.throat.color, onTap: @escaping () -> Void) {
    self.init(content: { Text(title) }, tone: tone, onTap: onTap)
  }
}

#Preview {
  ZStack {
    AuraBackground(level: .brow)

    VStack {
      KarmicHealingDisclosureGroup(
        content: {
          VStack(spacing: 0) {
            DisclosureCell("Group 1", onTap: {})
            DisclosureCell("Group 2", onTap: {})
            DisclosureCell("Group 3", onTap: {})
          }
        },
        tone: Spectrum.brow.color
      )
    }
    .font(Typography.title)
    .padding(.horizontal)
  }
}
