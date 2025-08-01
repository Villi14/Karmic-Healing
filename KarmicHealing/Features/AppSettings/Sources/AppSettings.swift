//
// Karmic Healing 2025
//

import ComposableArchitecture
import Common
import UIKit
import SwiftUI

@Reducer
public struct AppSettings {
  @Dependency(\.openURL) var openURL
  @Dependency(\.userDefaults) var userDefaults

  public init() {}

  @ObservableState
  public struct State: Equatable {
    @Presents var destination: Destination.State?
    var sessionDuration: Int = 5
    var soundEnabled: Bool = true
    var vibrationEnabled: Bool = true

    public init() {}
  }

  public enum Action: Equatable {
    case didTapAbout
    case destination(PresentationAction<Destination.Action>)
    case didTapChangeLanguage
    case didTapContactEmail
    case didTapSessionDuration
    case sessionDurationChanged(Int)
    case soundEnabledChanged(Bool)
    case vibrationEnabledChanged(Bool)
    case onAppear
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
      case .didTapSessionDuration:
        state.destination = .sessionDurationAlert(.init(currentDuration: state.sessionDuration))
        return .none
      case let .sessionDurationChanged(duration):
        state.sessionDuration = duration
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(duration, for: IntKey.sessionDuration)
        }
      case let .soundEnabledChanged(enabled):
        state.soundEnabled = enabled
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(enabled, for: BoolKey.soundEnabled)
        }
      case let .vibrationEnabledChanged(enabled):
        state.vibrationEnabled = enabled
        return .run { [userDefaults] _ in
          await userDefaults.setAsync(enabled, for: BoolKey.vibrationEnabled)
        }
      case .onAppear:
        let savedDuration = userDefaults.integer(for: .sessionDuration)
        if savedDuration > 0 {
          state.sessionDuration = savedDuration
        }
        state.soundEnabled = userDefaults.bool(for: .soundEnabled)
        state.vibrationEnabled = userDefaults.bool(for: .vibrationEnabled)
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
    case sessionDurationAlert(EnergyBalansingSettingsAlertState)
  }

  public enum Action: Equatable {
    case aboutAlert(Alert)
    case clipboardAlert(CopyAlert)
    case mailComposer(MailComposer)
    case sessionDurationAlert(EnergyBalansingSettingsAlertAction)

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
