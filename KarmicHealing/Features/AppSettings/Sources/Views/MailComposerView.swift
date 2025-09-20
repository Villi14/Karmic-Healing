// Karmic Healing 2025

import SwiftUI
import MessageUI

struct MailComposerView: UIViewControllerRepresentable {
  @Binding var isShowing: Bool

  static let canShowMailComposer = MFMailComposeViewController.canSendMail()

  final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
    @Binding var isShowing: Bool

    init(isShowing: Binding<Bool>) {
      _isShowing = isShowing
    }

    func mailComposeController(
      _ controller: MFMailComposeViewController,
      didFinishWith result: MFMailComposeResult,
      error: Error?
    ) {
      isShowing = false
    }
  }

  func makeCoordinator() -> Coordinator {
    return Coordinator(isShowing: $isShowing)
  }

  func makeUIViewController(
    context: UIViewControllerRepresentableContext<MailComposerView>
  ) -> MFMailComposeViewController {
    let vc = MFMailComposeViewController()
    vc.mailComposeDelegate = context.coordinator
    vc.setToRecipients(["karmic.healing14@gmail.com"])
    return vc
  }

  func updateUIViewController(
    _ uiViewController: MFMailComposeViewController,
    context: UIViewControllerRepresentableContext<MailComposerView>
  ) {}
}

