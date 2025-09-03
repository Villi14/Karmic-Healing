// Karmic Healing 2025

import SwiftUI
import Resources

public struct SearchBar: View {
  @Binding var text: String
  
  public init(text: Binding<String>) {
    self._text = text
  }
  
  public var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
      
      TextField("search".loc(), text: $text)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .accentColor(ResourcesAsset.Colors.clam.swiftUIColor)
      
      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle")
            .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        }
      }
    }
    .padding(DesignConstants.padding)
    .background{
      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
        .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)
    }
    .cornerRadius(DesignConstants.cornerRadius)
    .padding(.horizontal)
  }
}
