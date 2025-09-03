import IssueReporting
import SharingGRDB
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
  
  @ObservationIgnored @FetchOne var completedCount: Int = 0
  @ObservationIgnored @FetchAll var requests: [Row]
  
  @ObservationIgnored @Dependency(\.defaultDatabase) private var database
  
  func showCompletedButtonTapped() async {
    showCompletedInSearchResults.toggle()
    await updateQuery()
  }
  
  func deleteCompletedRequests(monthsAgo: Int? = nil) {
    withErrorReporting {
      try database.write { db in
        try Request
          .searching(searchText)
          .where(\.isCompleted)
          .where {
            if let monthsAgo {
              #sql("\($0.dueDate) < date('now', '-\(raw: monthsAgo) months')")
            }
          }
          .delete()
          .execute(db)
      }
    }
  }
  
  private func updateQuery() async {
    await withErrorReporting {
      if searchText.isEmpty {
        showCompletedInSearchResults = false
      }
      
      try await $completedCount.load(
        Request.searching(searchText)
          .where(\.isCompleted)
          .count(),
        animation: .default
      )
      
      try await $requests.load(
        Request
          .searching(searchText)
          .where {
            if !showCompletedInSearchResults {
              !$0.isCompleted
            }
          }
          .order { ($0.isCompleted, $0.dueDate) }
          .join(RequestsList.all) { $0.requestsListID.eq($1.id) }
          .select {
            Row.Columns(
              isPastDue: $0.isPastDue,
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
    let isPastDue: Bool
    let notes: String
    let request: Request
    let requestsList: RequestsList
  }
}

struct SearchRequestsView: View {
  let model: SearchRequestsModel
  
  init(model: SearchRequestsModel) {
    self.model = model
  }
  
  var body: some View {
    HStack {
      Text("\(model.completedCount) " + "completed".loc())
        .monospacedDigit()
        .contentTransition(.numericText())
      
      if model.completedCount > 0 {
        Text("•")
        
        Menu {
          Text("clear_completed_requests".loc())
          
          Button("older_than_1_month".loc()) {
            model.deleteCompletedRequests(monthsAgo: 1)
          }
          
          Button("older_than_6_months".loc()) {
            model.deleteCompletedRequests(monthsAgo: 6)
          }
          
          Button("older_than_1_year".loc()) {
            model.deleteCompletedRequests(monthsAgo: 12)
          }
          
          Button("all_completed".loc()) {
            model.deleteCompletedRequests()
          }
        } label: {
          Text("clear".loc())
        }
        
        Spacer()
        
        Button(model.showCompletedInSearchResults ? "hide".loc() : "show".loc()) {
          Task { await model.showCompletedButtonTapped() }
        }
      }
    }
    .tint(ResourcesAsset.Colors.clam.swiftUIColor)
    .buttonStyle(.borderless)
    
    ForEach(model.requests) { request in
      RequestRow(
        color: request.requestsList.color,
        isPastDue: request.isPastDue,
        notes: request.notes,
        request: request.request,
        requestsList: request.requestsList,
        showCompleted: model.showCompletedInSearchResults
      )
    }
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
        SearchRequestsView(model: SearchRequestsModel())
      } else {
        Text("tap_search".loc())
      }
    }
    .searchable(text: $searchText)
  }
}
