//
// Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Common
import UIKit
import SwiftUI

@Reducer
public struct AppSettings {
  @Dependency(\.openURL) var openURL

  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents var destination: Destination.State?

    public init() {}
  }

  public enum Action: Equatable {
    case didTapAbout
    case destination(PresentationAction<Destination.Action>)
    case didTapChangeLanguage
    case didTapContactEmail
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .didTapAbout:
        state.destination = .aboutAlert(.showAbout())
        return .none
      case .didTapChangeLanguage:
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
          return .none
        }
        return .run { _ in
          await openURL(settingsUrl)
        }
      case .didTapContactEmail:
        if MailComposerView.canShowMailComposer {
          state.destination = .mailComposer
        } else {
          state.destination = .clipboardAlert(.contactUs)
        }
        return .none
      case .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }
}

@Reducer
public struct Destination {
  @ObservableState
  public enum State: Equatable {
    case aboutAlert(KarmicHealingAlert<Action.Alert>.State)
    case clipboardAlert(KarmicHealingAlert<Action.CopyAlert>.State)
    case mailComposer
  }

  public enum Action: Equatable {
    case aboutAlert(Alert)
    case clipboardAlert(CopyAlert)
    case mailComposer(MailComposer)

    public enum Alert: Equatable {}
    public enum CopyAlert: Equatable {
      case copyToClipboard(String)
    }
    public enum MailComposer: Equatable {}
  }
}

extension KarmicHealingAlert<Destination.Action.Alert>.State {
  static func showAbout() -> Self {
    .init(
      image: Image(systemName: "info.circle"),
      title: String(localized: "about", bundle: .main),
      message: "Thanks for using Karmic Healing 2025"
    )
  }
}

extension KarmicHealingAlert<Destination.Action.CopyAlert>.State {
  static var contactUs: Self {
    let email = "karmic.healing@gmail.com"

    return .init(
      image: Image(systemName: "envelope"),
      title: String(localized: "write_to_us", bundle: .main),
      message: email,
      buttons: [
        .init(
          label: String(localized: "Copy to Clipboard", bundle: .main),
          action: .copyToClipboard(email)
        )
      ]
    )
  }
}
