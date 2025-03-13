//
// Karmic Healing 2025
//

import SwiftUI
import Resources

public struct HomeButton: Equatable {
  let color: SwiftUI.Color
  let icon: Image
  let title: String
}

extension HomeButton {
  public static var balancingEnуergyButton: Self {
    .init(
      color: ResourcesAsset.Colors.health.swiftUIColor,
      icon: Image(systemName: "apple.meditate"),
      title: String(localized: "energy_balancing", bundle: .main).uppercased()
    )
  }

  public static var requestsButton: Self {
    .init(
      color: ResourcesAsset.Colors.energy.swiftUIColor,
      icon: Image(systemName: "staroflife"),
      title: String(localized: "requests", bundle: .main).uppercased()
    )
  }

  public static var notesButton: Self {
    .init(
      color: ResourcesAsset.Colors.clam.swiftUIColor,
      icon: Image(systemName: "pencil.and.list.clipboard"),
      title: String(localized: "notes", bundle: .main).uppercased()
    )
  }

  public static var settingsButton: Self {
    .init(
      color: ResourcesAsset.Colors.friendly.swiftUIColor,
      icon: Image(systemName: "gearshape"),
      title: String(localized: "settings", bundle: .main).uppercased()
    )
  }
}
