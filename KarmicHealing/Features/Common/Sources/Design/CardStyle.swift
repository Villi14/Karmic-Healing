//
// Karmic Healing 2025
//

import SwiftUI
import Resources

public enum CardElevation: Equatable, Sendable {
  case elevated
  case flat
}

/// Paper: content lifts off the aura on a warm shadow and catches light along a
/// half-pixel top edge. Radius 20 rather than 12 — the larger radius reads calmer.
public struct CardStyle: ViewModifier {
  private let tone: Color?
  private let cornerRadius: CGFloat
  private let showsWatermark: Bool
  private let elevation: CardElevation
  private let gradient: LinearGradient?

  public init(
    tone: Color? = nil,
    cornerRadius: CGFloat = DesignConstants.cornerRadiusLarge,
    showsWatermark: Bool = false,
    elevation: CardElevation = .elevated,
    gradient: LinearGradient? = nil
  ) {
    self.tone = tone
    self.cornerRadius = cornerRadius
    self.showsWatermark = showsWatermark
    self.elevation = elevation
    self.gradient = gradient
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
  }

  public func body(content: Content) -> some View {
    content
      .background {
        shape
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
          .overlay(alignment: .bottomTrailing) {
            if showsWatermark, tone != nil {
              RingsWatermark(gradient: gradient ?? AuraGradient.accent)
            }
          }
          .overlay {
            shape.strokeBorder(
              gradient ?? AuraGradient.edge,
              lineWidth: DesignConstants.lineWidthThin
            )
          }
          .clipShape(shape)
      }
      .shadow(
        color: elevation == .elevated
          ? .black.opacity(DesignConstants.opacityCardShadow)
          : .clear,
        radius: elevation == .elevated ? DesignConstants.shadowRadiusCard : 0,
        x: 0,
        y: elevation == .elevated ? DesignConstants.shadowOffsetCard : 0
      )
  }
}

extension View {
  /// Puts the view on paper. Pass a `tone` with `showsWatermark` to add the
  /// ring motif under the card's corner.
  public func cardStyle(
    tone: Color? = nil,
    cornerRadius: CGFloat = DesignConstants.cornerRadiusLarge,
    showsWatermark: Bool = false,
    elevation: CardElevation = .elevated,
    gradient: LinearGradient? = nil
  ) -> some View {
    modifier(CardStyle(
      tone: tone,
      cornerRadius: cornerRadius,
      showsWatermark: showsWatermark,
      elevation: elevation,
      gradient: gradient
    ))
  }

  /// Convenience for a card that takes its tone from a spectrum level.
  public func cardStyle(
    level: Spectrum,
    cornerRadius: CGFloat = DesignConstants.cornerRadiusLarge,
    showsWatermark: Bool = true,
    elevation: CardElevation = .elevated
  ) -> some View {
    modifier(CardStyle(
      tone: level.color,
      cornerRadius: cornerRadius,
      showsWatermark: showsWatermark,
      elevation: elevation,
      gradient: AuraGradient.gradient(for: level)
    ))
  }
}
