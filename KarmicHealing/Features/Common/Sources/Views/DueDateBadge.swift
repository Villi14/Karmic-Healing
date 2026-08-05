//
// Karmic Healing 2025
//

import SwiftUI
import Resources

public struct DueDateBadge: View {
  private let date: Date
  private let isPastDue: Bool
  private let level: Spectrum

  public init(date: Date, isPastDue: Bool, level: Spectrum = .solar) {
    self.date = date
    self.isPastDue = isPastDue
    self.level = level
  }

  public var body: some View {
    HStack(spacing: DesignConstants.paddingSmall) {
      Image(systemName: isPastDue ? "exclamationmark.circle.fill" : "calendar")

      Text(date, style: .date)

      if isPastDue {
        Text("overdue".loc)
      }
    }
    .font(Typography.caption)
    .foregroundStyle(
      isPastDue
        ? AnyShapeStyle(AuraGradient.gradient(for: level))
        : AnyShapeStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
    )
    .accessibilityElement(children: .combine)
  }
}
