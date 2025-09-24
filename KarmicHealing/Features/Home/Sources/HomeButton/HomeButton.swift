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
  public static var balancingEnergyButton: Self {
    .init(
      color: ResourcesAsset.Colors.health.swiftUIColor,
      icon: Image(systemName: "apple.meditate"),
      title: "energy_balancing".loc.uppercased()
    )
  }
  
  public static var requestsButton: Self {
    .init(
      color: ResourcesAsset.Colors.energy.swiftUIColor,
      icon: Image(systemName: "staroflife"),
      title: "requests".loc.uppercased()
    )
  }
  
  public static var remindersButton: Self {
    .init(
      color: ResourcesAsset.Colors.friendly.swiftUIColor,
      icon: Image(systemName: "pencil.and.list.clipboard"),
      title: "reminders".loc.uppercased()
    )
  }
  
  public static var settingsButton: Self {
    .init(
      color: ResourcesAsset.Colors.clam.swiftUIColor,
      icon: Image(systemName: "gearshape"),
      title: "settings".loc.uppercased()
    )
  }
}
