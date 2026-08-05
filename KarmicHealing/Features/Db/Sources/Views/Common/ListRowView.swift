import SwiftUI
import Common
import Resources

struct ListRowView: View {
  let count: Int
  let color: Color
  let title: String
  /// The glyph a row without a radio button shows, so a topic can look like a topic.
  var iconName: String = "list.bullet"
  /// Turns the leading icon into a radio button. Rows without it show a plain list glyph.
  var completion: Completion? = nil
  var onTap: (() -> Void)? = nil
  var onDelete: (() -> Void)? = nil
  var onEdit: (() -> Void)? = nil

  /// Rows without a radio button — reminders lists — are never struck through.
  private var isCompleted: Bool { completion?.isCompleted == true }

  /// The state of a row's radio button, and what a tap on it does.
  struct Completion {
    var isCompleted: Bool
    var isEnabled: Bool
    var toggle: () -> Void
  }

  var body: some View {
    HStack {
      if let completion {
        Button(action: completion.toggle) {
          Image(systemName: completion.isCompleted ? "circle.inset.filled" : "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(AuraGradient.gradient(for: color))
            .opacity(completion.isEnabled ? 1 : DesignConstants.opacityMedium)
            .padding(.leading, DesignConstants.paddingLarge)
            .animation(Motion.touch, value: completion.isCompleted)
        }
        .disabled(!completion.isEnabled)
        .padding(.trailing, 0)
      } else {
        Image(systemName: iconName)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameHeightSmall)
          .foregroundStyle(AuraGradient.gradient(for: color))
          .padding(.leading, DesignConstants.paddingLarge)
      }
      HStack {
        Text(title)
          .foregroundStyle(
            isCompleted
            ? ResourcesAsset.Colors.textSecondary.swiftUIColor
            : ResourcesAsset.Colors.textPrimary.swiftUIColor
          )
          .strikethrough(isCompleted, pattern: .solid, color: ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .font(Typography.listTitle)
        Spacer()
      }
      .contentShape(Rectangle())
      .onTapGesture {
        onTap?()
      }

      if let onEdit = onEdit {
        Image(systemName: "info.circle")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: DesignConstants.frameHeightSmall)
          .foregroundStyle(AuraGradient.gradient(for: color))
          .padding(.horizontal, DesignConstants.paddingLarge)
          .onTapGesture {
            onEdit()
          }
      }

      if count > 0 {
        Text("\(count)")
          .font(Typography.figure)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .padding(.trailing, DesignConstants.paddingLarge)
      }
    }
    .frame(height: DesignConstants.frameHeightXXLarge)
    .cardStyle(
      tone: color,
      showsWatermark: true,
      elevation: .flat,
      gradient: AuraGradient.gradient(for: color)
    )
    .rowSwipeActions(onDelete: onDelete, onEdit: onEdit)
  }
}

extension View {
  /// The buttons a row hides behind a swipe. Topics, requests, subrequests and reminders are
  /// the same kind of thing to the user, so they show the same glyphs in the same colours
  /// rather than one screen's icons and another's words. A reminder adds the flag; the rest
  /// leave that slot empty.
  func rowSwipeActions(
    onDelete: (() -> Void)? = nil,
    onEdit: (() -> Void)? = nil,
    flag: FlagAction? = nil
  ) -> some View {
    swipeActions {
      if let onDelete {
        Button(action: onDelete) {
          Image(systemName: "trash")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
        }
        .tint(ResourcesAsset.Colors.energy.swiftUIColor)
      }
      if let onEdit {
        Button(action: onEdit) {
          Image(systemName: "info.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
        }
        .tint(ResourcesAsset.Colors.clarity.swiftUIColor)
      }
      if let flag {
        Button(action: flag.toggle) {
          Image(systemName: flag.isFlagged ? "flag.slash" : "flag")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
        }
        .tint(ResourcesAsset.Colors.friendly.swiftUIColor)
      }
    }
  }
}

/// The thing a row hangs from — the topic of a reminder, the request of a subrequest — wearing
/// that thing's own colour. Shown on the screens where rows from several parents stand side by
/// side, so a row never floats free of where it belongs.
struct RowBadge: View {
  let title: String
  let tone: Color
  var iconName: String

  var body: some View {
    HStack(spacing: DesignConstants.paddingSmall) {
      Image(systemName: iconName)

      Text(title)
        .lineLimit(1)
    }
    .karmicLabel(tone: tone)
    .accessibilityElement(children: .combine)
  }
}

/// Whether a row is flagged, and what a tap on the flag does.
struct FlagAction {
  var isFlagged: Bool
  var toggle: () -> Void
}

#Preview {
  NavigationStack {
    List {
      ListRowView(
        count: 10,
        color: .blue,
        title: "Personal",
        onEdit:  {}
      )
    }
  }
}
