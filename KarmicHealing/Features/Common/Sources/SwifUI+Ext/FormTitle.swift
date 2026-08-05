//
// Karmic Healing 2025
//

import SwiftUI
import Resources

extension View {
  /// A screen title that sits below the toolbar and takes the whole width.
  ///
  /// Forms are presented with Cancel and Save on either side of the navigation bar, and a
  /// title in the gap between them has barely half the screen to live in — long ones are cut
  /// short. Given the full width, the title wraps instead.
  ///
  /// Apply it to the form itself, before its background, so the aura runs behind the title too.
  public func karmicFormTitle(_ title: String) -> some View {
    navigationBarTitleDisplayMode(.inline)
      .safeAreaInset(edge: .top, spacing: 0) {
        Text(title)
          .font(Typography.title)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .frame(maxWidth: .infinity)
          .padding(.horizontal, DesignConstants.paddingLarge)
          .padding(.bottom, DesignConstants.padding)
      }
  }
}
