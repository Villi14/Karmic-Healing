//
// Karmic Healing 2025
//

import SwiftUI
import Resources

/// The app's button: tinted by the current spectrum level, pressing it lands on
/// the interaction curve.
public struct KarmicButtonStyle: ButtonStyle {
  public enum Prominence: Sendable {
    /// Filled with the tone — the one action that moves the screen forward.
    case filled
    /// Tone on a wash of itself — secondary actions.
    case quiet
  }

  private let tone: Color
  private let prominence: Prominence
  private let gradient: LinearGradient?

  public init(
    tone: Color = Spectrum.throat.color,
    prominence: Prominence = .filled,
    gradient: LinearGradient? = nil
  ) {
    self.tone = tone
    self.prominence = prominence
    self.gradient = gradient
  }

  public func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Typography.body.weight(.semibold))
      .foregroundStyle(foreground)
      .padding(.horizontal, DesignConstants.paddingXLarge)
      .frame(minWidth: DesignConstants.frameWidthXLarge, minHeight: DesignConstants.frameHeightXLarge)
      .background {
        RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusLarge, style: .continuous)
          .fill(background)
      }
      .scaleEffect(configuration.isPressed ? DesignConstants.pressedScale : 1)
      .animation(Motion.touch, value: configuration.isPressed)
  }

  private var foreground: Color {
    switch prominence {
    // The spectrum is bright in both themes, so a filled button always carries dark ink —
    // `textInvert` would flip to near-white in the light theme and disappear into the fill.
    case .filled: ResourcesAsset.Colors.onAccent.swiftUIColor
    case .quiet: tone
    }
  }

  private var background: AnyShapeStyle {
    switch prominence {
    case .filled: AnyShapeStyle(gradient ?? AuraGradient.accent)
    case .quiet: AnyShapeStyle(gradient ?? AuraGradient.soft)
    }
  }
}

extension ButtonStyle where Self == KarmicButtonStyle {
  public static func karmic(
    tone: Color = Spectrum.throat.color,
    prominence: KarmicButtonStyle.Prominence = .filled,
    gradient: LinearGradient? = nil
  ) -> KarmicButtonStyle {
    KarmicButtonStyle(tone: tone, prominence: prominence, gradient: gradient)
  }

  public static func karmic(
    level: Spectrum,
    prominence: KarmicButtonStyle.Prominence = .filled
  ) -> KarmicButtonStyle {
    KarmicButtonStyle(
      tone: level.color,
      prominence: prominence,
      gradient: AuraGradient.gradient(for: level)
    )
  }
}
