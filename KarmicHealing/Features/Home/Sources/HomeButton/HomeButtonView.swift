//
// Karmic Healing 2025
//

import SwiftUI
import Resources

public struct HomeButtonView: View {
  let size: CGSize
  let homeButton: HomeButton

  public init(
    size: CGSize,
    homeButton: HomeButton
  ) {
    self.size = size
    self.homeButton = homeButton
  }

  public var body: some View {
    ZStack {
      homeButton.color

      VStack(alignment: .leading) {
        HStack {
          homeButton.icon
            .resizable()
            .foregroundColor(ResourcesAsset.Colors.textInvert.swiftUIColor)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 24)
            .padding(.leading, 16)
            .padding(.top, 16)

          Spacer()

          Rectangle()
            .frame(width: 8, height: 8)
            .cornerRadius(4)
            .foregroundColor(ResourcesAsset.Colors.textInvert.swiftUIColor)
            .padding(.trailing, 16)
        }

        Spacer()

        Text(homeButton.title)
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(ResourcesAsset.Colors.textInvert.swiftUIColor)
          .multilineTextAlignment(.leading)
          .padding(.horizontal, 16)

        Rectangle()
          .frame(width: 80, height: 2)
          .foregroundColor(ResourcesAsset.Colors.textInvert.swiftUIColor)
          .padding(.horizontal, 16)

        Spacer()
      }
    }
    .frame(width: size.width, height: size.height)
    .cornerRadius(12)
    .shadow(radius: 4)
  }
}

#Preview {
  ZStack {
    ResourcesAsset.Colors.background.swiftUIColor
      .ignoresSafeArea()

    HomeButtonView(
      size: CGSize(width: 393 / 2, height: 393 / 2 * 0.615384615),
      homeButton: .init(
        color: ResourcesAsset.Colors.clam.swiftUIColor,
        icon: Image(systemName: "info.circle"),
        title: String(localized: "About", bundle: .main).uppercased()
      )
    )
  }
}
