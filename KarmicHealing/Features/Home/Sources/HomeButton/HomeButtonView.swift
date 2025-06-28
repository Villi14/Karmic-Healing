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
    VStack {
      VStack(alignment: .leading) {
        HStack {
          homeButton.icon
            .resizable()
            .foregroundStyle(homeButton.color)
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 24)
            .padding(.leading, 24)
            .padding(.top, 16)
          
          Spacer()
          
          Rectangle()
            .frame(width: 8, height: 8)
            .cornerRadius(4)
            .foregroundStyle(homeButton.color)
            .padding(.trailing, 16)
        }
        
        Spacer()
        
        Text(homeButton.title)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          .multilineTextAlignment(.leading)
          .padding(.horizontal, 24)
        
        Rectangle()
          .frame(width: 80, height: 2)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .padding(.horizontal, 24)
        
        Spacer()
      }
    }
    .frame(width: size.width, height: size.height)
    .background{
      ResourcesAsset.Colors.cellBackground.swiftUIColor
      
      RoundedRectangle(cornerRadius: 12)
        .inset(by: 0.5)
        .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.5), lineWidth: 0.5)
    }
    .cornerRadius(12)
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
