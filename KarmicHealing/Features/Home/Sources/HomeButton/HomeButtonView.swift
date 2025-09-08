//
// Karmic Healing 2025
//

import SwiftUI
import Resources
import Common

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
    VStack(alignment: .leading) {
      HStack {
        homeButton.icon
          .resizable()
          .foregroundStyle(homeButton.color)
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: DesignConstants.maxWidthSmall)
          .padding(.leading, DesignConstants.paddingXLarge)
          .padding(.top, DesignConstants.paddingLarge)
        
        Spacer()
        
        Rectangle()
          .frame(width: DesignConstants.frameWidthSmall, height: DesignConstants.frameWidthSmall)
          .cornerRadius(DesignConstants.cornerRadiusSmall)
          .foregroundStyle(homeButton.color)
          .padding(.trailing, DesignConstants.paddingLarge)
      }
      
      Spacer()
      
      Text(homeButton.title)
        .font(.caption.weight(.medium))
        .minimumScaleFactor(0.5)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, DesignConstants.paddingXLarge)
    
      Spacer()
    }
    .frame(width: size.width, height: size.height)
    .background{
      ResourcesAsset.Colors.cellBackground.swiftUIColor
    }
    .cornerRadius(DesignConstants.cornerRadiusMedium)
  }
}

#Preview {
  ZStack {
    ResourcesAsset.Colors.background.swiftUIColor
      .ignoresSafeArea()
    
    HomeButtonView(
      size: CGSize(width: DesignConstants.maxWidthMedium,
                   height: DesignConstants.maxWidthMedium * DesignConstants.goldenRatio),
      homeButton: .init(
        color: ResourcesAsset.Colors.clam.swiftUIColor,
        icon: Image(systemName: "info.circle"),
        title: "About".loc().uppercased()
      )
    )
  }
}
