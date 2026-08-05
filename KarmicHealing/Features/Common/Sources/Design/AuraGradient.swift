//
// Karmic Healing 2025
//

import SwiftUI

/// Two neighbouring colours from the Aura spectrum.
///
/// Every visual element uses the colour of its current Aura level and the
/// colour immediately after it. This keeps each gradient simple while the
/// sections still retain their own place in the spectrum.
public enum AuraGradient {
  public static func gradient(for level: Spectrum) -> LinearGradient {
    let nextLevel = Spectrum(rawValue: level.rawValue + 1)
      ?? Spectrum(rawValue: level.rawValue - 1)
      ?? level

    return LinearGradient(
      colors: [level.color, nextLevel.color],
      startPoint: .bottomLeading,
      endPoint: .topTrailing
    )
  }

  /// The same two-tone sheen built from a colour the user picked rather than from a level.
  /// A topic or a request carries its own colour, and the card it sits on has to show it —
  /// so the second stop is that colour lightened rather than the next chakra.
  public static func gradient(for tone: Color) -> LinearGradient {
    LinearGradient(
      colors: [tone, tone.mix(with: .white, by: 0.3)],
      startPoint: .bottomLeading,
      endPoint: .topTrailing
    )
  }

  public static func horizontal(for level: Spectrum) -> LinearGradient {
    let nextLevel = Spectrum(rawValue: level.rawValue + 1)
      ?? Spectrum(rawValue: level.rawValue - 1)
      ?? level

    return LinearGradient(
      colors: [level.color, nextLevel.color],
      startPoint: .leading,
      endPoint: .trailing
    )
  }

  public static func soft(for level: Spectrum) -> LinearGradient {
    let nextLevel = Spectrum(rawValue: level.rawValue + 1)
      ?? Spectrum(rawValue: level.rawValue - 1)
      ?? level

    return LinearGradient(
      colors: [level.color.opacity(0.22), nextLevel.color.opacity(0.16)],
      startPoint: .bottomLeading,
      endPoint: .topTrailing
    )
  }

  public static func edge(for level: Spectrum) -> LinearGradient {
    let nextLevel = Spectrum(rawValue: level.rawValue + 1)
      ?? Spectrum(rawValue: level.rawValue - 1)
      ?? level

    return LinearGradient(
      colors: [nextLevel.color.opacity(0.65), level.color.opacity(0.12)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  /// Fallback for shared controls that do not carry a screen level.
  public static let accent = gradient(for: .throat)
  public static let soft = soft(for: .throat)
  public static let edge = edge(for: .throat)
}
