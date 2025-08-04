// Karmic Healing 2025

import SwiftUI
import Resources

public struct BgWithGradientView: View {
  public init() {}

  public var body: some View {
    LinearGradient(
      gradient: Gradient(colors: [
        ResourcesAsset.Colors.clam.swiftUIColor.opacity(DesignConstants.opacityLow),
        ResourcesAsset.Colors.background.swiftUIColor
      ]),
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
}
