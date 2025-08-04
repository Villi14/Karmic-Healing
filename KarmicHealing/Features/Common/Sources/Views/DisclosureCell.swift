//
// Karmic Healing 2025
//

import Resources
import SwiftUI

public struct DisclosureCell<Content: View>: View {
  private let content: () -> Content
  private let onTap: () -> Void
  
  public init(content: @escaping () -> Content, onTap: @escaping () -> Void) {
    self.content = content
    self.onTap = onTap
  }
  
  public var body: some View {
    Button(action: onTap, label: {
      ZStack {
        HStack {
          self.content().foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
          
          Spacer()
          
          Image(systemName: "chevron.right")
            .renderingMode(.template)
            .resizable()
            .frame(width: DesignConstants.paddingMedium, height: DesignConstants.paddingLarge)
            .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        }
      }
    })
    .frame(height: DesignConstants.frameHeightXXLarge)
    .padding(.horizontal)
  }
}

public struct KarmicHealingDisclosureGroup<Content: View>: View {
  private let content: () -> Content
  private let cornerRadius: Double
  private let backgroundColor: SwiftUI.Color
  
  public init(
    @ViewBuilder content: @escaping () -> Content,
    cornerRadius: Double = DesignConstants.cornerRadiusMedium,
    backgroundColor: SwiftUI.Color = ResourcesAsset.Colors.cellBackground.swiftUIColor
  ) {
    self.content = content
    self.cornerRadius = cornerRadius
    self.backgroundColor = backgroundColor
  }
  
  public var body: some View {
    self.content()
      .background {
        RoundedRectangle(cornerRadius: self.cornerRadius)
          .fill(self.backgroundColor)
      }
  }
}

extension DisclosureCell where Content == Text {
  public init(_ title: String, onTap: @escaping () -> Void) {
    self.content = { Text(title) }
    self.onTap = onTap
  }
}

#Preview {
  ZStack {
    BgWithGradientView()
    
    VStack {
      DisclosureCell("123", onTap: {})
        .padding(.bottom)
      
      KarmicHealingDisclosureGroup {
        VStack {
          DisclosureCell("Group 1", onTap: {})
          DisclosureCell("Group 2", onTap: {})
          DisclosureCell("Group 3", onTap: {})
        }
      }
    }
    .foregroundStyle(.white)
    .padding(.horizontal)
  }
}

