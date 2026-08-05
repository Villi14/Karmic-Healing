import SQLiteData
import SwiftUI
import Common
import Resources

/// The request itself at the top of its subrequest list: its title, its note, and the radio
/// button that fulfils it once its subrequests let it through.
struct RequestDetailHeader: View {
  let color: Color

  @FetchOne var request: RequestsList
  @FetchAll var subrequests: [Request]

  @Dependency(\.defaultDatabase) private var database

  init(requestsList: RequestsList, color: Color) {
    self.color = color
    _request = FetchOne(wrappedValue: requestsList, RequestsList.find(requestsList.id))
    _subrequests = FetchAll(
      Request.where { $0.requestsListID.eq(requestsList.id) },
      animation: .default
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: DesignConstants.paddingSmall) {
      // The screen names what it is before it names which one, the way a topic's screen does.
      Text("request".loc)
        .karmicLabel(tone: color)

      HStack(alignment: .firstTextBaseline) {
        Button(action: toggleCompletion) {
          Image(systemName: request.isCompleted ? "circle.inset.filled" : "circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: DesignConstants.frameHeightSmall)
            .foregroundStyle(AuraGradient.gradient(for: color))
            .opacity(canToggle ? 1 : DesignConstants.opacityMedium)
            .animation(Motion.touch, value: request.isCompleted)
        }
        .disabled(!canToggle)
        .buttonStyle(.borderless)

        Text(request.title)
          .font(Typography.title)
          .foregroundStyle(color)
          .strikethrough(
            request.isCompleted,
            pattern: .solid,
            color: ResourcesAsset.Colors.textSecondary.swiftUIColor
          )
          .fixedSize(horizontal: false, vertical: true)

        Spacer(minLength: 0)
      }

      if !request.notes.isEmpty {
        Text(request.notes)
          .font(Typography.bodySecondary)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .fixedSize(horizontal: false, vertical: true)
      }

      if !canToggle {
        Text("request_locked_hint".loc)
          .font(Typography.bodySecondary)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var canToggle: Bool {
    RequestsList.canToggleCompletion(
      request,
      progress: SubrequestProgress(
        total: subrequests.count,
        completed: subrequests.filter(\.isCompleted).count
      )
    )
  }

  private func toggleCompletion() {
    withErrorReporting {
      try database.write { db in
        try RequestsList.toggleCompletion(of: request.id, in: db)
      }
    }
  }
}
