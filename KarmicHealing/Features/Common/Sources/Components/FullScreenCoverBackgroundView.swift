//
// Karmic Healing 2025
//

import SwiftUI

public struct FullScreenCoverBackgroundView: UIViewRepresentable {
  let backgroundColor: UIColor
  let blurEffectStyle: UIBlurEffect.Style?

  public init(backgroundColor: UIColor, blurEffectStyle: UIBlurEffect.Style? = nil) {
    self.backgroundColor = backgroundColor
    self.blurEffectStyle = blurEffectStyle
  }

  public func makeUIView(context: Context) -> UIView {
    if let blurEffectStyle {
      return InnerBlurredView(backgroundColor: self.backgroundColor, blurEffectStyle: blurEffectStyle)
    } else {
      return InnerView(backgroundColor: self.backgroundColor)
    }
  }

  public func updateUIView(_ uiView: UIView, context: Context) { }

  private class InnerView: UIView {
    let color: UIColor

    public init(backgroundColor: UIColor) {
      self.color = backgroundColor
      super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      superview?.superview?.backgroundColor = self.color
    }
  }

  private class InnerBlurredView: UIVisualEffectView {
    let color: UIColor

    public init(backgroundColor: UIColor, blurEffectStyle: UIBlurEffect.Style) {
      self.color = backgroundColor
      super.init(effect: UIBlurEffect(style: blurEffectStyle))
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
      super.didMoveToWindow()
      superview?.superview?.backgroundColor = self.color
    }
  }
}
