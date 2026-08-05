//
// Karmic Healing 2025
//

import SwiftUI
import Resources

/// The app's ground: a few very faint colour blooms drifting over the base
/// background, taking their hue from the current screen's Aura level.
public struct AuraBackground: View {
  private let tone: Color

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.auraMotionPaused) private var motionPaused

  private var isStill: Bool { reduceMotion || motionPaused }

  public init(tone: Color) {
    self.tone = tone
  }

  public init(level: Spectrum = .throat) {
    self.init(tone: level.color)
  }

  public var body: some View {
    TimelineView(.animation(minimumInterval: Motion.breathTick, paused: isStill)) { context in
      let phase = reduceMotion ? 1 : Motion.breathPhase(at: context.date)

      MeshGradient(
        width: 3,
        height: 3,
        points: [
          [0, 0], [0.5, 0], [1, 0],
          [0, 0.5], [Float(0.4 + 0.2 * phase), Float(0.45 + 0.1 * phase)], [1, 0.5],
          [0, 1], [0.5, 1], [1, 1]
        ],
        colors: [
          tone.opacity(0.10), tone.opacity(0.06), .clear,
          tone.opacity(0.05), tone.opacity(0.12), tone.opacity(0.04),
          .clear, tone.opacity(0.03), .clear
        ]
      )
      .animation(Motion.touch, value: tone)
    }
    .background(ResourcesAsset.Colors.background.swiftUIColor)
    .ignoresSafeArea()
  }
}

#Preview {
  AuraBackground(level: .heart)
}
