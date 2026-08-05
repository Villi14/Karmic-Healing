//
// Karmic Healing 2025
//

import SwiftUI
import Common

public struct HomeButton: Equatable {
  /// Where the destination sits on the spectrum — it tints the card.
  let level: Spectrum
  let icon: Image
  let title: String

  var color: SwiftUI.Color { level.color }
}

extension HomeButton {
  public static var balancingEnergyButton: Self {
    .init(
      level: .heart,
      icon: Image(systemName: "apple.meditate"),
      title: "energy_balancing".loc
    )
  }

  public static var requestsButton: Self {
    .init(
      level: .sacral,
      icon: Image(systemName: "staroflife"),
      title: "requests".loc
    )
  }

  public static var remindersButton: Self {
    .init(
      level: .solar,
      icon: Image(systemName: "pencil.and.list.clipboard"),
      title: "reminders".loc
    )
  }

  public static var settingsButton: Self {
    .init(
      level: .brow,
      icon: Image(systemName: "gearshape"),
      title: "settings".loc
    )
  }
}
