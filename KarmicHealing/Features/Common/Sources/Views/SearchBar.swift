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
        .foregroundStyle(AuraGradient.gradient(for: .throat))
      
      TextField("search".loc, text: $text)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .accentColor(Spectrum.throat.color)
      
      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle")
            .foregroundStyle(AuraGradient.gradient(for: .throat))
        }
      }
    }
    .padding(DesignConstants.paddingMedium)
    .cardStyle()
    .padding(.horizontal)
  }
}
