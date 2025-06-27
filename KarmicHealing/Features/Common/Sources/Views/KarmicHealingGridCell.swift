// Karmic Healing 2025

import SwiftUI
import Resources

public struct KarmicHealingGridCell: View {
  let color: Color
  let count: Int?
  let iconName: String
  let title: String
  let action: () -> Void

  public init(
    color: Color,
    count: Int? = nil,
    iconName: String,
    title: String,
    action: @escaping () -> Void
  ) {
    self.color = color
    self.count = count
    self.iconName = iconName
    self.title = title
    self.action = action
  }

  public var body: some View {
    Button(action: action) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 8) {

          Image(systemName: iconName)
            .font(.largeTitle)
            .bold()
            .foregroundStyle(color)
            .background(
              Color.white.clipShape(Circle()).padding(4)
            )

          Text(title)
            .font(.headline)
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            .bold()
            .padding(.leading, 4)
        }

        Spacer()

        if let count {
          Text("\(count)")
            .font(.title)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        }
      }
      .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
      .background(ResourcesAsset.Colors.cellBackground.swiftUIColor)
      .cornerRadius(16)
    }
  }
}
