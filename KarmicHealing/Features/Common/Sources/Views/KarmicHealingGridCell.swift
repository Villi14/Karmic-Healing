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
            .resizable()
            .foregroundStyle(color)
            .aspectRatio(contentMode: .fit)
            .frame(height: 18)
            .padding(.top, 4)
          
          Text(title)
            .font(.headline)
            .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
            .bold()
            .padding(.top, 4)
        }
        
        Spacer()
        
        if let count {
          Text("\(count)")
            .font(.title3)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
        }
      }
      .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
      .background{
        RoundedRectangle(cornerRadius: 12)
          .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
        
        RoundedRectangle(cornerRadius: 12)
          .inset(by: 0.5)
          .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.5), lineWidth: 0.5)
      }
      .cornerRadius(12)
    }
  }
}
