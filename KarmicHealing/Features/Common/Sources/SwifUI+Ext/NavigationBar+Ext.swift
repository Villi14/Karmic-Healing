//
// Karmic Healing 2025
//

import SwiftUI

extension View {
  public func navigationBarBackgroundColor(_ color: SwiftUI.Color) -> some View {
    UINavigationBarAppearance.configure { $0.backgroundColor = UIColor(color) }
    return self
  }

  public func navigationBarTitleColor(_ color: SwiftUI.Color) -> some View {
    let uiColor = UIColor(color)
    UINavigationBarAppearance.configure {
      // Screen titles are set in New York, like every other heading.
      $0.titleTextAttributes = [
        .foregroundColor: uiColor,
        .font: UIFont.karmicSerif(.headline)
      ]
      $0.largeTitleTextAttributes = [
        .foregroundColor: uiColor,
        .font: UIFont.karmicSerif(.largeTitle)
      ]
    }
    return self
  }
}

extension UINavigationBarAppearance {
  static func configure(_ configure: (UINavigationBarAppearance) -> Void) {
    let appearance = UINavigationBarAppearance()
    appearance.configureWithTransparentBackground()

    // Restore standard style to prevent overriding it each time this function is called
    let standardAppearance = UINavigationBar.appearance().standardAppearance
    appearance.backgroundColor = standardAppearance.backgroundColor
    appearance.titleTextAttributes = standardAppearance.titleTextAttributes
    appearance.largeTitleTextAttributes = standardAppearance.largeTitleTextAttributes

    configure(appearance)

    UINavigationBar.appearance().standardAppearance = appearance
    UINavigationBar.appearance().compactAppearance = appearance
    UINavigationBar.appearance().scrollEdgeAppearance = appearance
  }
}
