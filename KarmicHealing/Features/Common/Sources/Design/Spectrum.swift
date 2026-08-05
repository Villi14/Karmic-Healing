//
// Karmic Healing 2025
//

import SwiftUI
import Resources

/// The seven colours already in `Colors.xcassets`, read as what they are:
/// an ordered chakra spectrum from root to crown.
///
/// Every screen takes a level and tints itself from it, so colour carries
/// position in the app rather than decoration.
public enum Spectrum: Int, CaseIterable, Sendable, Comparable {
  /// Root — warnings, deletion.
  case root = 0
  /// Sacral — requests.
  case sacral
  /// Solar plexus — reminders.
  case solar
  /// Heart — balancing energy.
  case heart
  /// Throat — the main accent, navigation.
  case throat
  /// Brow — settings.
  case brow
  /// Crown — "About", summaries.
  case crown

  public var color: Color {
    switch self {
    case .root: ResourcesAsset.Colors.energy.swiftUIColor
    case .sacral: ResourcesAsset.Colors.friendly.swiftUIColor
    case .solar: ResourcesAsset.Colors.clarity.swiftUIColor
    case .heart: ResourcesAsset.Colors.health.swiftUIColor
    case .throat: ResourcesAsset.Colors.clam.swiftUIColor
    case .brow: ResourcesAsset.Colors.peace.swiftUIColor
    case .crown: ResourcesAsset.Colors.wisdom.swiftUIColor
    }
  }

  public static func < (lhs: Spectrum, rhs: Spectrum) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  /// The level a session has climbed to at `progress` (0…1), root → crown.
  public static func level(at progress: Double) -> Spectrum {
    let clamped = min(max(progress, 0), 1)
    let index = Int((clamped * Double(allCases.count - 1)).rounded())
    return Spectrum(rawValue: index) ?? .root
  }

  /// The tint at `progress` (0…1), blended across neighbouring levels so a
  /// rising session shifts hue continuously instead of snapping between steps.
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
