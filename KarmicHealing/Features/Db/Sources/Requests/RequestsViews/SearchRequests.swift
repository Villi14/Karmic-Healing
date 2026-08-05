import IssueReporting
import SQLiteData
import SwiftUI
import Common
import Resources

@MainActor
@Observable
class SearchRequestsModel {
  var showCompletedInSearchResults = false
  var searchText = "" {
    didSet {
      Task { await updateQuery() }
    }
  }

  @ObservationIgnored @FetchOne var completedRequestCount: Int = 0
  @ObservationIgnored @FetchOne var completedSubrequestCount: Int = 0
  /// Requests whose own title, description or notes match.
  @ObservationIgnored @FetchAll var requests: [RequestsList]
  /// Subrequests that match, each carrying the request it belongs to.
  @ObservationIgnored @FetchAll var subrequests: [Row]

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  var hasResults: Bool { !requests.isEmpty || !subrequests.isEmpty }

  /// Search hides what is fulfilled on both levels, so the tally that offers to show it counts
  /// both — otherwise a fulfilled request matches, is hidden, and nothing on screen says so.
  var completedCount: Int { completedRequestCount + completedSubrequestCount }

  func showCompletedButtonTapped() async {
    showCompletedInSearchResults.toggle()
    await updateQuery()
  }

  /// Nothing here carries a date of its own to sift by, so this clears every fulfilled match on
  /// both levels. A fulfilled request takes its subrequests with it — the schema cascades.
  func deleteCompletedRequests() {
    withErrorReporting {
      try database.write { db in
        try RequestsList
          .searching(searchText)
          .where(\.isCompleted)
          .delete()
          .execute(db)

        try Request
          .searching(searchText)
          .where(\.isCompleted)
          .delete()
          .execute(db)
      }
    }
  }

  /// Reloads both result sets. Internal so tests can await it instead of racing the `didSet`.
  func updateQuery() async {
    await withErrorReporting {
      if searchText.isEmpty {
        showCompletedInSearchResults = false
      }

      try await $completedRequestCount.load(
        RequestsList.searching(searchText)
          .where(\.isCompleted)
          .count(),
        animation: .default
      )

      try await $completedSubrequestCount.load(
        Request.searching(searchText)
          .where(\.isCompleted)
          .count(),
        animation: .default
      )

      try await $requests.load(
        RequestsList
          .searching(searchText)
          .where {
            if !showCompletedInSearchResults {
              !$0.isCompleted
            }
          }
          .order { ($0.isCompleted, $0.position) },
        animation: .default
      )

      try await $subrequests.load(
        Request
          .searching(searchText)
          .where {
            if !showCompletedInSearchResults {
              !$0.isCompleted
            }
          }
          .order { ($0.isCompleted, $0.position) }
          .join(RequestsList.all) { $0.requestsListID.eq($1.id) }
          .select {
            Row.Columns(
              notes: $0.inlineNotes,
              request: $0,
              requestsList: $1
            )
          },
        animation: .default
      )
    }
  }

  @Selection
  struct Row: Identifiable {
    var id: Request.ID { request.id }
    let notes: String
    let request: Request
    let requestsList: RequestsList
  }
}

struct SearchRequestsView: View {
  let model: SearchRequestsModel
  let onRequestTapped: (RequestsList) -> Void

  init(model: SearchRequestsModel, onRequestTapped: @escaping (RequestsList) -> Void) {
    self.model = model
    self.onRequestTapped = onRequestTapped
  }

  var body: some View {
    HStack {
      Text("\(model.completedCount) " + "completed".loc)
        .monospacedDigit()
        .contentTransition(.numericText())

      if model.completedCount > 0 {
        Text("•")

        Menu {
          Text("clear_completed_requests".loc)

          Button("all_completed".loc, role: .destructive) {
            model.deleteCompletedRequests()
          }
        } label: {
          Text("clear".loc)
        }

        Spacer()

        Button(model.showCompletedInSearchResults ? "hide".loc : "show".loc) {
          Task { await model.showCompletedButtonTapped() }
        }
      }
    }
    .tint(Spectrum.sacral.color)
    .buttonStyle(.borderless)

    if !model.hasResults {
      KarmicEmptyStateView(
        iconName: "magnifyingglass",
        title: "no_results".loc,
        message: "try_another_search".loc,
        tone: Spectrum.sacral.color,
        level: .sacral
      )
      .listRowBackground(Color.clear)
    } else {
      if !model.requests.isEmpty {
        Section {
          ForEach(model.requests) { requestsList in
            RequestsListRow(
              requestsList: requestsList,
              onTap: { onRequestTapped(requestsList) }
            )
          }
        } header: {
          sectionHeader("request".loc)
        }
        .listRowBackground(Color.clear)
      }

      if !model.subrequests.isEmpty {
        Section {
          ForEach(model.subrequests) { row in
            RequestRow(
              color: row.requestsList.color,
              notes: row.notes,
              request: row.request,
              requestsList: row.requestsList,
              showCompleted: model.showCompletedInSearchResults,
              showsRequest: true
            )
          }
        } header: {
          sectionHeader("sub_request".loc)
        }
        .listRowBackground(Color.clear)
      }
    }
  }

  private func sectionHeader(_ title: String) -> some View {
    Text(title)
      .font(Typography.bodySecondary)
      .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
      .textCase(nil)
  }
}

#Preview {
  @Previewable @State var searchText = "take"
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }

  NavigationStack {
    List {
      if !searchText.isEmpty {
        SearchRequestsView(model: SearchRequestsModel(), onRequestTapped: { _ in })
      } else {
        Text("tap_search".loc)
      }
    }
    .searchable(text: $searchText)
  }
}
