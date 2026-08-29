//
// Karmic Healing 2026
//

import Dependencies
import SwiftUI
import Resources

/// Choosing the code, typed once and then again to be sure of it.
///
/// The same screen serves the first code and every later change: there is nothing to prove
/// before setting one, because it is only ever reached from inside an app already unlocked.
public struct PasscodeSetupView: View {
  private enum Stage: Equatable, Hashable {
    case create
    case confirm(first: String)
  }

  @Dependency(\.passcode) private var passcode
  @Environment(\.dismiss) private var dismiss

  @State private var stage: Stage = .create
  @State private var message: String?

  private let onFinished: () -> Void
  private let onCancel: (() -> Void)?

  public init(onFinished: @escaping () -> Void, onCancel: (() -> Void)? = nil) {
    self.onFinished = onFinished
    self.onCancel = onCancel
  }

  public var body: some View {
    ZStack {
      AuraBackground(level: .brow)

      VStack(spacing: DesignConstants.sectionSpacing) {
        Text("app_lock".loc)
          .font(Typography.heading)
          .multilineTextAlignment(.center)

        PasscodePad(title: title, message: message ?? subtitle) { code in
          accept(code)
        }
        .id(stage)

        Button("cancel".loc) {
          onCancel?()
          dismiss()
        }
        .buttonStyle(.karmic(tone: Spectrum.brow.color, prominence: .quiet))
      }
      .padding(.horizontal, DesignConstants.paddingXLarge)
      .padding(.vertical, DesignConstants.screenVerticalPadding)
      .karmicContentWidth(DesignConstants.maxAlertWidth)
    }
  }

  private var title: String {
    switch stage {
    case .create: "passcode_create_title".loc
    case .confirm: "passcode_repeat_title".loc
    }
  }

  private var subtitle: String? {
    switch stage {
    case .create: "passcode_create_subtitle".loc
    case .confirm: nil
    }
  }

  private func accept(_ code: String) -> Bool {
    switch stage {
    case .create:
      message = nil
      stage = .confirm(first: code)
      return true

    case let .confirm(first):
      guard code == first else {
        // Back to the start rather than to another try at the second entry: whichever of the
        // two was mistyped, the code is no longer one the user can be said to have chosen.
        stage = .create
        message = "passcode_mismatch".loc
        return false
      }

      passcode.save(code)
      onFinished()
      dismiss()
      return true
    }
  }
}
