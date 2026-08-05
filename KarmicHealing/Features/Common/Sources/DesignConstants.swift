import SwiftUI

public enum DesignConstants {
    // Device
    /// iPad draws the same text styles and glyphs as an iPhone on a far larger sheet of
    /// glass, which reads as a phone app that got stretched. Everything expressive —
    /// type, icons, the session rings — comes up by this factor there. Spacing and
    /// padding deliberately stay put: the extra room on iPad comes from the layout
    /// having more of it, not from thicker gaps.
    public static let contentScale: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 1.35 : 1

    /// A drawn size at the current device's scale.
    public static func scaled(_ value: CGFloat) -> CGFloat { value * contentScale }

    /// A single column of content never runs wider than this, so a card or a line of
    /// text on iPad stays as readable as it is on a phone instead of spanning the pane.
    public static let maxContentWidth: CGFloat = 700

    /// An alert is a dialog, not a page: it keeps a phone-like width everywhere.
    public static let maxAlertWidth: CGFloat = 480

    // Padding
    public static let paddingTiny: CGFloat = 2
    public static let paddingSmall: CGFloat = 4
    public static let padding: CGFloat = 8
    public static let paddingMedium: CGFloat = 12
    public static let paddingLarge: CGFloat = 16
    public static let paddingXLarge: CGFloat = 24
    public static let paddingXXLarge: CGFloat = 32
    public static let paddingNegativeSmall: CGFloat = -6
    public static let paddingNegative: CGFloat = -8
    public static let paddingNegativeLarge: CGFloat = -16
    public static let paddingNegativeXLarge: CGFloat = -28
    public static let bottomPaddingLarge: CGFloat = 50

    // Corner radius
    /// Cards and buttons in the "Aura" direction — the larger radius reads calmer.
    public static let cornerRadiusLarge: CGFloat = scaled(20)

    // Spacing
    public static let spacingSmall: CGFloat = 8
    public static let spacingMedium: CGFloat = 12
    public static let spacing: CGFloat = 16
    public static let spacingLarge: CGFloat = 20
    public static let spacingXLarge: CGFloat = 32
    
    // Help view specific constants
    public static let helpIconSize: CGFloat = scaled(60)
    public static let helpStepCircleSize: CGFloat = scaled(40)
    public static let helpStepCircleSizeSmall: CGFloat = scaled(30)
    public static let helpStepSpacing: CGFloat = 12
    public static let helpTipSpacing: CGFloat = 8
    
    // Onboarding specific constants
    public static let onboardingIconContainerHeight: CGFloat = helpIconSize + paddingLarge * 2
    public static let onboardingSkipButtonHeight: CGFloat = scaled(60)
    
    // Frame sizes
    public static let frameHeightSmall: CGFloat = scaled(18)
    public static let frameHeightMedium: CGFloat = scaled(36)
    public static let frameHeightXLarge: CGFloat = scaled(48)
    public static let frameHeightXXLarge: CGFloat = scaled(56)
    public static let frameWidthSmall: CGFloat = scaled(8)
    public static let frameWidthMedium: CGFloat = scaled(12)
    public static let frameWidthXLarge: CGFloat = scaled(80)
    
    // Max frame sizes
    public static let maxWidthSmall: CGFloat = scaled(24)
    public static let maxWidthMedium: CGFloat = scaled(300)
    public static let maxHeightLarge: CGFloat = scaled(500)
    
    // Lines a notes field shows before it starts growing with the text
    public static let notesLineLimit: Int = 4

    // Opacity
    public static let opacityLow: Double = 0.1
    public static let opacityMedium: Double = 0.5
    /// The ring watermark under a card's corner.
    public static let opacityWatermark: Double = 0.3
    /// The half-pixel light edge along the top of a card.
    public static let opacityEdgeLight: Double = 0.25
    public static let opacityCardShadow: Double = 0.18

    // Aura
    /// The ring motif watermarking a card.
    public static let watermarkSize: CGFloat = scaled(96)
    public static let watermarkOffset: CGFloat = scaled(34)
    /// Filled core of the session ring.
    public static let ringCoreSize: CGFloat = scaled(12)
    /// Rest size of the breathing ring, relative to its expanded size.
    public static let breathScale: CGFloat = 0.9
    /// Scale a button settles at while held.
    public static let pressedScale: CGFloat = 0.97
    /// The breathing ring on a session step.
    public static let breathingRingSize: CGFloat = scaled(78)
    /// One rung of the session ladder.
    public static let rungSize: CGFloat = scaled(9)
    public static let rungHaloWidth: CGFloat = scaled(4)

    // Line width
    public static let lineWidthThin: CGFloat = 0.5
    public static let lineWidth: CGFloat = 2

    // Shadow
    public static let shadowRadiusCard: CGFloat = 16
    public static let shadowOffsetCard: CGFloat = 8

    // Threshold
    public static let thresholdMedium: CGFloat = 50

    /// Width/height of a home card.
    public static let cardAspectRatio: CGFloat = 1 / 0.78
}

extension View {
    /// Holds a column of content to a readable width and centres it in whatever room
    /// it is given. A no-op on a phone, where the screen is already narrower than the
    /// cap; on iPad it keeps cards, forms and text from stretching across the pane.
    public func karmicContentWidth(
        _ width: CGFloat = DesignConstants.maxContentWidth
    ) -> some View {
        frame(maxWidth: width)
            .frame(maxWidth: .infinity)
    }
}
