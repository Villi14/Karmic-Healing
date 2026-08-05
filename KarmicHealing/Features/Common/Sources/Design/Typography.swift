//
// Karmic Healing 2025
//

import SwiftUI
import Resources

/// Serif for the voice, grotesque for the interface.
///
/// New York ships with iOS as `.system(design: .serif)` — no bundled font, full
/// Cyrillic coverage. It sets screen titles, step titles and card names.
/// Everything functional is SF Pro; figures are SF Pro Light so they read as a
/// measurement rather than as text.
///
/// Every face is a text style, so it follows Dynamic Type, and on iPad it also takes
/// `DesignConstants.contentScale` — the same text style renders identically on both
/// devices, which leaves an iPad reading like an enlarged phone. These are computed
/// properties rather than stored ones so the point size is re-read from the current
/// content-size category on every render.
public enum Typography {
  /// New York — screen title.
  public static var display: Font { font(.largeTitle, design: .serif) }

  /// New York — heading inside a screen.
  public static var heading: Font { font(.title1, design: .serif) }

  /// New York — step title, section heading.
  public static var title: Font { font(.title3, design: .serif) }

  /// New York — card name.
  public static var cardTitle: Font { font(.subheadline, design: .serif) }

  /// SF Pro — compact titles in dense lists.
  public static var listTitle: Font { font(.body, weight: .medium) }

  /// SF Pro — body copy.
  public static var body: Font { font(.body) }

  /// SF Pro — supporting copy.
  public static var bodySecondary: Font { font(.callout) }

  /// SF Pro — the smallest supporting copy: a badge, a numbered step.
  public static var caption: Font { font(.caption1) }

  /// SF Pro Semibold — uppercase eyebrow. Apply with `.karmicLabel(tone:)`.
  public static var label: Font { font(.caption2, weight: .semibold) }

  /// SF Pro Light — figures and counts.
  public static var figure: Font { font(.title1, weight: .light).monospacedDigit() }

  /// SF Symbols that stand on their own — a toolbar glyph, a control on a card.
  public static var icon: Font { font(.title3) }

  /// Letter spacing for the uppercase eyebrow.
  public static let labelTracking: CGFloat = 1.2

  private static func font(
    _ style: UIFont.TextStyle,
    weight: Font.Weight? = nil,
    design: Font.Design = .default
  ) -> Font {
    let size = UIFont.preferredFont(forTextStyle: style).pointSize * DesignConstants.contentScale
    let font = Font.system(size: size, design: design)
    return weight.map { font.weight($0) } ?? font
  }
}

extension UIFont {
  /// New York at the given text style — the UIKit side of `Typography`,
  /// for the places SwiftUI can't reach (the navigation bar).
  public static func karmicSerif(_ style: UIFont.TextStyle) -> UIFont {
    let base = UIFont.preferredFont(forTextStyle: style)
    let size = base.pointSize * DesignConstants.contentScale
    guard let descriptor = base.fontDescriptor.withDesign(.serif) else {
      return base.withSize(size)
    }
    return UIFont(descriptor: descriptor, size: size)
  }
}

extension View {
  /// The uppercase eyebrow above a step or a section: "КРОК 4 ІЗ 14".
  public func karmicLabel(tone: Color? = nil) -> some View {
    modifier(KarmicLabel(tone: tone))
  }
}

private struct KarmicLabel: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme
  let tone: Color?

  func body(content: Content) -> some View {
    content
      .font(Typography.label)
      .textCase(.uppercase)
      .tracking(Typography.labelTracking)
      .foregroundStyle(ink)
  }

  /// The spectrum is tuned to read on a dark surface. As tiny uppercase text on a light one it
  /// has to come down, or the eyebrow washes out against the page.
  private var ink: Color {
    guard let tone else { return ResourcesAsset.Colors.textSecondary.swiftUIColor }
    return colorScheme == .light ? tone.mix(with: .black, by: 0.3) : tone
  }
}
