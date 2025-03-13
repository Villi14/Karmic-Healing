// Karmic Healing 2025

import SwiftUI
import Resources

extension TabView {
  public var setTabViewdIndicatorColor: some View {
    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(ResourcesAsset.Colors.friendly.swiftUIColor)
    UIPageControl.appearance().pageIndicatorTintColor = UIColor(ResourcesAsset.Colors.textInvert.swiftUIColor)
    return self
  }
}
