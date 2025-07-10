// Karmic Healing 2025

import SwiftUI
import Resources

public struct KarmicHealingSearchBar: View {
  @Binding var text: String

  public init(text: Binding<String>) {
    self._text = text
  }

  public var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)

      TextField(String(localized: "search", bundle: .main), text: $text)
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
        .accentColor(ResourcesAsset.Colors.clam.swiftUIColor)
      
      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle")
            .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
        }
      }
    }
    .padding(8)
    .background{
      RoundedRectangle(cornerRadius: 12)
        .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)

      RoundedRectangle(cornerRadius: 12)
        .inset(by: 0.5)
        .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(0.5), lineWidth: 0.5)
    }
    .cornerRadius(10)
    .padding(.horizontal)
  }
}
