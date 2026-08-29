//
// Karmic Healing 2026
//

import SwiftUI
import Resources

/// The app's own way of asking for a code: a row of dots and a grid of digits, in place of a
/// text field and the system keyboard.
///
/// The pad owns the digits typed into it and hands them over only once there are enough of them.
/// `onComplete` answers whether they were the right ones — a `false` shakes the dots empty for
/// another try, a `true` leaves them filled while the screen behind moves on.
public struct PasscodePad: View {
  private let title: String
  private let message: String?
  private let level: Spectrum
  private let length: Int
  private let biometryIconName: String?
  private let isDisabled: Bool
  private let onComplete: (String) -> Bool
  private let onBiometry: (() -> Void)?

  @State private var entered = ""
  @State private var shakes = 0

  public init(
    title: String,
    message: String? = nil,
    level: Spectrum = .brow,
    length: Int = PasscodeClient.length,
    biometryIconName: String? = nil,
    isDisabled: Bool = false,
    onBiometry: (() -> Void)? = nil,
    onComplete: @escaping (String) -> Bool
  ) {
    self.title = title
    self.message = message
    self.level = level
    self.length = length
    self.biometryIconName = biometryIconName
    self.isDisabled = isDisabled
    self.onBiometry = onBiometry
    self.onComplete = onComplete
  }

  public var body: some View {
    VStack(spacing: DesignConstants.sectionSpacing) {
      VStack(spacing: DesignConstants.spacingMedium) {
        Text(title)
          .font(Typography.title)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)

        dots

        // Held even when there is nothing to say, so the keypad does not jump a line
        // up and down as messages come and go.
        Text(message ?? " ")
          .font(Typography.caption)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .frame(minHeight: DesignConstants.frameHeightSmall)
      }

      keypad
    }
    .disabled(isDisabled)
    .opacity(isDisabled ? DesignConstants.opacityMedium : 1)
    .animation(Motion.touch, value: isDisabled)
  }

  // MARK: - Dots

  private var dots: some View {
    HStack(spacing: DesignConstants.spacingMedium) {
      ForEach(0..<length, id: \.self) { index in
        Circle()
          .strokeBorder(AuraGradient.edge(for: level), lineWidth: DesignConstants.lineWidth)
          .background {
            Circle()
              .fill(index < entered.count ? AnyShapeStyle(AuraGradient.gradient(for: level)) : AnyShapeStyle(.clear))
          }
          .frame(width: DesignConstants.rungSize + DesignConstants.paddingSmall, height: DesignConstants.rungSize + DesignConstants.paddingSmall)
      }
    }
    .animation(Motion.touch, value: entered.count)
    .modifier(ShakeEffect(shakes: CGFloat(shakes)))
    .accessibilityElement()
    .accessibilityLabel(title)
    .accessibilityValue("\(entered.count)")
  }

  // MARK: - Keypad

  private var keypad: some View {
    VStack(spacing: DesignConstants.spacingMedium) {
      ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: DesignConstants.spacingLarge) {
          ForEach(row, id: \.self) { digit in
            digitKey(digit)
          }
        }
      }

      HStack(spacing: DesignConstants.spacingLarge) {
        cornerKey {
          if let biometryIconName, let onBiometry {
            Button(action: onBiometry) {
              Image(systemName: biometryIconName)
                .font(Typography.icon)
                .foregroundStyle(AuraGradient.gradient(for: level))
                .frame(width: Self.keySize, height: Self.keySize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("unlock_with_face_id".loc)
          }
        }

        digitKey(0)

        cornerKey {
          if !entered.isEmpty {
            Button(action: delete) {
              Image(systemName: "delete.left")
                .font(Typography.icon)
                .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
                .frame(width: Self.keySize, height: Self.keySize)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("passcode_delete".loc)
          }
        }
      }
    }
  }

  private func digitKey(_ digit: Int) -> some View {
    Button {
      append(digit)
    } label: {
      Text("\(digit)")
        .font(Typography.figure)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .frame(width: Self.keySize, height: Self.keySize)
        .background {
          Circle()
            .fill(AuraGradient.soft(for: level))
            .overlay {
              Circle().stroke(AuraGradient.edge(for: level), lineWidth: DesignConstants.lineWidthThin)
            }
        }
    }
    .buttonStyle(PasscodeKeyStyle())
    .accessibilityLabel("\(digit)")
  }

  /// Keeps the bottom row's spacing whether or not the corner holds a button — an empty view
  /// takes up no room at all, which would slide the zero out from under the eight.
  private func cornerKey<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    ZStack {
      Color.clear
      content()
    }
    .frame(width: Self.keySize, height: Self.keySize)
  }

  // MARK: - Typing

  private func append(_ digit: Int) {
    guard entered.count < length else { return }

    entered.append("\(digit)")
    tap(.light)

    guard entered.count == length else { return }

    let code = entered
    // A beat, so the last dot is seen filling before the screen answers.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
      guard entered == code else { return }
      if onComplete(code) { return }
      reject()
    }
  }

  private func delete() {
    guard !entered.isEmpty else { return }
    entered.removeLast()
    tap(.light)
  }

  private func reject() {
    tap(.rigid)
    withAnimation(Motion.touch) { shakes += 1 }
    entered = ""
  }

  private func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
  }

  private static let rows = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]

  /// Comfortably past the 44pt the guidelines ask for, and small enough that four rows still
  /// fit above the fold on a 4.7" phone.
  private static var keySize: CGFloat { DesignConstants.scaled(DesignConstants.compact(72, 62)) }
}

/// A key settles a little deeper than a card does — it is meant to feel like a button.
private struct PasscodeKeyStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.92 : 1)
      .opacity(configuration.isPressed ? DesignConstants.opacityMedium : 1)
      .animation(Motion.touch, value: configuration.isPressed)
  }
}

/// The side-to-side refusal of a wrong code: three quick passes, ending where it started.
private struct ShakeEffect: GeometryEffect {
  var shakes: CGFloat

  var animatableData: CGFloat {
    get { shakes }
    set { shakes = newValue }
  }

  func effectValue(size: CGSize) -> ProjectionTransform {
    let travel = sin(shakes * .pi * 6) * 10
    return ProjectionTransform(CGAffineTransform(translationX: travel, y: 0))
  }
}
