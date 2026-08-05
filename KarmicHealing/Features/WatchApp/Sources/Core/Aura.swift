//
// Karmic Healing 2025
//

import SwiftUI

/// The watch's copy of the "Aura" design language. The watch target is
/// deliberately standalone, so the spectrum and the type scale are mirrored
/// here rather than imported from `Common`.
public enum Spectrum: Int, CaseIterable, Sendable {
  case root = 0
  case sacral
  case solar
  case heart
  case throat
  case brow
  case crown

  public var color: Color {
    switch self {
    case .root: KarmicHealingWatchAsset.Colors.energy.swiftUIColor
    case .sacral: KarmicHealingWatchAsset.Colors.friendly.swiftUIColor
    case .solar: KarmicHealingWatchAsset.Colors.clarity.swiftUIColor
    case .heart: KarmicHealingWatchAsset.Colors.health.swiftUIColor
    case .throat: KarmicHealingWatchAsset.Colors.clam.swiftUIColor
    case .brow: KarmicHealingWatchAsset.Colors.peace.swiftUIColor
    case .crown: KarmicHealingWatchAsset.Colors.wisdom.swiftUIColor
    }
  }

  /// The tint at `progress` (0…1), blended across neighbouring levels.
  public static func tone(at progress: Double) -> Color {
    let clamped = min(max(progress, 0), 1)
    let position = clamped * Double(allCases.count - 1)
    let lower = Int(position)
    let upper = min(lower + 1, allCases.count - 1)
    guard let low = Spectrum(rawValue: lower), let high = Spectrum(rawValue: upper) else {
      return Spectrum.throat.color
    }
    return low.color.mix(with: high.color, by: position - Double(lower))
  }
}

public enum Typography {
  /// New York — headings and step titles.
  public static let title = Font.system(.headline, design: .serif)
  public static let cardTitle = Font.system(.caption, design: .serif)
  public static let body = Font.system(.footnote)
  public static let label = Font.system(.caption2).weight(.semibold)
}

public enum Motion {
  public static let touch: Animation = .spring(response: 0.35, dampingFraction: 0.75)
}
