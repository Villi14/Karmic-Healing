//
// Karmic Healing 2025
//

import SwiftUI

/// One geometric motif for the whole app: thin concentric circles.
/// Card watermark, step indicator, completion bloom — all the same shape,
/// drawn by SwiftUI, no asset involved.
public struct Rings: Shape {
  public var count: Int
  /// Radius of the innermost ring as a fraction of the outermost one.
  public var innerRatio: CGFloat

  public init(count: Int = 3, innerRatio: CGFloat = 1.0 / 3.0) {
    self.count = count
    self.innerRatio = innerRatio
  }

  public func path(in rect: CGRect) -> Path {
    var path = Path()
    guard count > 0 else { return path }

    let center = CGPoint(x: rect.midX, y: rect.midY)
    let outer = min(rect.width, rect.height) / 2
    let inner = outer * innerRatio
    let step = count > 1 ? (outer - inner) / CGFloat(count - 1) : 0

    for index in 0..<count {
      let radius = inner + step * CGFloat(index)
      path.addEllipse(
        in: CGRect(
          x: center.x - radius,
          y: center.y - radius,
          width: radius * 2,
          height: radius * 2
        )
      )
    }
    return path
  }
}

/// The session ring: concentric circles with a filled core, breathing on the
/// ambient curve. Holds still when the system asks for reduced motion.
public struct BreathingRings: View {
  private let tone: Color
  private let count: Int
  private let gradient: LinearGradient?

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.auraMotionPaused) private var motionPaused

  private var isStill: Bool { reduceMotion || motionPaused }

  public init(tone: Color, count: Int = 3, gradient: LinearGradient? = nil) {
    self.tone = tone
    self.count = count
    self.gradient = gradient
  }

  public var body: some View {
    TimelineView(.animation(minimumInterval: Motion.breathTick, paused: isStill)) { context in
      let phase = reduceMotion ? 1 : Motion.breathPhase(at: context.date)

      ZStack {
        Rings(count: count)
          .stroke(
            (gradient ?? AuraGradient.accent).opacity(DesignConstants.opacityMedium),
            lineWidth: DesignConstants.lineWidthThin * 2
          )
          .scaleEffect(lerp(DesignConstants.breathScale, 1, phase))

        Circle()
          .fill(gradient ?? AuraGradient.accent)
          .frame(width: DesignConstants.ringCoreSize, height: DesignConstants.ringCoreSize)
          .opacity(lerp(DesignConstants.opacityMedium, 1, phase))
      }
    }
  }

  private func lerp(_ from: Double, _ to: Double, _ phase: Double) -> Double {
    from + (to - from) * phase
  }
}

/// The ring watermark that sits under a card's corner.
struct RingsWatermark: View {
  let gradient: LinearGradient

  var body: some View {
    Rings(count: 3)
      .stroke(gradient, lineWidth: DesignConstants.lineWidthThin * 2)
      .frame(width: DesignConstants.watermarkSize, height: DesignConstants.watermarkSize)
      .opacity(DesignConstants.opacityWatermark)
      .offset(x: DesignConstants.watermarkOffset, y: DesignConstants.watermarkOffset)
      .allowsHitTesting(false)
  }
}
