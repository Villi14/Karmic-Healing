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
    .padding(DesignConstants.padding)
    .background{
      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
        .fill(ResourcesAsset.Colors.cellBackground.swiftUIColor)

      RoundedRectangle(cornerRadius: DesignConstants.cornerRadiusMedium)
        .inset(by: DesignConstants.lineWidthThin)
        .stroke(ResourcesAsset.Colors.textSecondary.swiftUIColor.opacity(DesignConstants.opacityMedium), lineWidth: DesignConstants.lineWidthThin)
    }
    .cornerRadius(DesignConstants.cornerRadius)
    .padding(.horizontal)
  }
}
