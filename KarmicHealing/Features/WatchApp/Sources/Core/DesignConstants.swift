import SwiftUI

public enum DesignConstants {
  // Padding
  public static let paddingTiny: CGFloat = 2
  public static let paddingSmall: CGFloat = 4
  public static let padding: CGFloat = 8
  public static let paddingMedium: CGFloat = 12

  // Corner radius
  /// Cards in the "Aura" direction — the larger radius reads calmer.
  public static let cornerRadiusLarge: CGFloat = 20

  // Spacing
  public static let spacing: CGFloat = 16

  // Aura
  /// Width of the tone stripe that marks a card's level.
  public static let toneStripeWidth: CGFloat = 3

  // Watch specific constants
  public static let watchVStackSpacing: CGFloat = 0
  public static let watchMinimumScaleFactor: Double = 0.7
  public static let watchTitleBottomPadding: CGFloat = 2
  public static let watchScrollBottomPadding: CGFloat = 30
  public static let watchButtonHorizontalPadding: CGFloat = 8
  public static let watchButtonVerticalPadding: CGFloat = 6
  public static let watchDisabledOpacity: Double = 0.3
  public static let watchEnabledOpacity: Double = 1.0
  public static let watchNavigationHorizontalPadding: CGFloat = 20
  public static let watchNavigationTopPadding: CGFloat = 4
  public static let watchSwipeThreshold: CGFloat = 50
  /// The countdown ring that shows when the slide turns next.
  public static let watchRingSize: CGFloat = 14
  public static let watchRingLineWidth: CGFloat = 2
  /// The black resting layer fades at the same gentle pace as the phone's brightness ramp.
  public static let watchScreenFadeDuration: TimeInterval = 0.8
}
