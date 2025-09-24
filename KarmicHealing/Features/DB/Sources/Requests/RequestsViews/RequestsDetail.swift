import CasePaths
import SharingGRDB
import SwiftUI
import SwiftUINavigation
import Common
import Resources

@MainActor
@Observable
class RequestsDetailModel: HashableObject {
  @ObservationIgnored @FetchAll var requestRows: [Row]
  @ObservationIgnored @Shared var ordering: Ordering
  @ObservationIgnored @Shared var showCompleted: Bool
  @ObservationIgnored @Dependency(\.defaultDatabase) private var database
  
  let detailType: DetailType
  var isNewRequestSheetPresented = false
  
  init(detailType: DetailType) {
    self.detailType = detailType
    _ordering = Shared(wrappedValue: .dueDate, .appStorage("ordering_list_\(detailType.id)"))
    _showCompleted = Shared(
      wrappedValue: detailType == .completed,
      .appStorage("show_completed_list_\(detailType.id)")
    )
    _requestRows = FetchAll(requestsQuery)
  }
  
  func orderingButtonTapped(_ ordering: Ordering) async {
    $ordering.withLock { $0 = ordering }
    await updateQuery()
  }
  
  func showCompletedButtonTapped() async {
    $showCompleted.withLock { $0.toggle() }
    await updateQuery()
  }
  
  func toggleRequestsListCompletion(_ requestsList: RequestsList) async {
    withErrorReporting {
      try database.write { db in
        // Check if all subordinate requests are completed using database query
        let totalRequests = try Request.where { $0.requestsListID == requestsList.id }.fetchCount(db)
        let completedRequests = try Request.where { $0.requestsListID == requestsList.id && $0.isCompleted }.fetchCount(db)
        
        // Only allow toggling if all subordinate requests are completed
        guard totalRequests > 0 && totalRequests == completedRequests else {
          return // Don't allow toggling if not all requests are completed
        }
        
        let newCompletionStatus = !requestsList.isCompleted
        
        // Update only the RequestsList completion status
        try RequestsList
          .find(requestsList.id)
          .update { $0.isCompleted = newCompletionStatus }
          .execute(db)
        
        // Don't update subordinate requests - they remain unchanged
      }
    }
    
    // Refresh the query to show updated completion status
    await updateQuery()
  }
  
  func move(from source: IndexSet, to destination: Int) async {
    withErrorReporting {
      try database.write { db in
        var ids = requestRows.map(\.request.id)
        ids.move(fromOffsets: source, toOffset: destination)
        
        try Request
          .where { $0.id.in(ids) }
          .update {
            let ids = Array(ids.enumerated())
            let (first, rest) = (ids.first!, ids.dropFirst())
            $0.position =
            rest
              .reduce(Case($0.id).when(first.element, then: first.offset)) { cases, id in
                cases.when(id.element, then: id.offset)
              }
              .else($0.position)
          }
          .execute(db)
      }
    }
    await updateQuery()
  }
  
  private func updateQuery() async {
    await withErrorReporting {
      try await $requestRows.load(requestsQuery, animation: .default)
      print("DEBUG: RequestsDetailModel updateQuery - requestRows count: \(requestRows.count)")
    }
  }
  
  private var requestsQuery: some StructuredQueriesCore.Statement<Row> {
    let query =
    Request
      .where { request in
        switch detailType {
        case .all: !request.isCompleted
        case .completed: request.isCompleted
        case .requestsList(let list): request.requestsListID.eq(list.id)
        case .scheduled: request.isScheduled
        case .today: request.isToday
        }
      }
      .where { request in
        // For RequestsList, always show all requests regardless of completion status
        if case .requestsList = detailType {
          true
        } else if !showCompleted {
          !request.isCompleted
        } else {
          true
        }
      }
      .order { $0.position }
      .order {
        switch ordering {
        case .dueDate: $0.dueDate.asc(nulls: .last)
        case .priority: $0.priority.desc()
        case .title: $0.title
        }
      }
      .join(RequestsList.all) { $0.requestsListID.eq($1.id) }
      .select {
        Row.Columns(
          request: $0,
          requestsList: $1,
          isPastDue: $0.isPastDue,
          notes: $0.inlineNotes.substr(0, 200)
        )
      }
    return query
  }
  
  enum Ordering: String, CaseIterable {
    case dueDate = "Due Date"
    case priority = "Priority"
    case title = "Title"
    
    var localizedTitle: String {
      switch self {
      case .dueDate:
        return "due_date".loc
      case .priority:
        return "priority".loc
      case .title:
        return "title".loc
      }
    }
    
    var icon: Image {
      switch self {
      case .dueDate: Image(systemName: "calendar")
      case .priority: Image(systemName: "chart.bar")
      case .title: Image(systemName: "textformat.characters")
      }
    }
  }
  
  @CasePathable
  @dynamicMemberLookup
  enum DetailType: Hashable {
    case all
    case completed
    case requestsList(RequestsList)
    case scheduled
    case today
  }
  
  @Selection
  struct Row: Identifiable {
    var id: Request.ID { request.id }
    let request: Request
    let requestsList: RequestsList
    let isPastDue: Bool
    let notes: String
  }
}

struct RequestsDetailView: View {
  @SwiftUI.Environment(\.dismiss) var dismiss
  @Bindable var model: RequestsDetailModel
  
  @State var isNavigationTitleVisible = false
  @State var navigationTitleHeight: CGFloat = 36
  
  var body: some View {
    ZStack {
      BgWithGradientView()
      
      List {
        VStack(alignment: .leading) {
          GeometryReader { proxy in
            HStack {
              Text(model.detailType.navigationTitle)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(model.detailType.color)
              
              Spacer()
            }
            .onAppear { navigationTitleHeight = proxy.size.height }
          }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.bottom, DesignConstants.paddingLarge)
        
        ForEach(model.requestRows) { row in
          RequestRow(
            color: model.detailType.color,
            isPastDue: row.isPastDue,
            notes: row.notes,
            request: row.request,
            requestsList: row.requestsList,
            showCompleted: model.showCompleted,
          )
        }
        .listRowBackground(Color.clear)
      }
      .navigationBarBackButtonHidden()
      .navigationBarTitleDisplayMode(.automatic)
      .navigationBarTitleColor(ResourcesAsset.Colors.textPrimary.swiftUIColor)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button(action: { dismiss() }) {
            Image(systemName: "chevron.left")
              .renderingMode(.template)
              .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
          }
        }
      }
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.y + geometry.contentInsets.top > navigationTitleHeight
      } action: {
        isNavigationTitleVisible = $1
      }
      .listStyle(.plain)
      .sheet(isPresented: $model.isNewRequestSheetPresented) {
        if let requestsList = model.detailType.requestsList {
          NavigationStack {
            RequestFormView(
              request: Request.Draft(requestsListID: requestsList.id),
              requestsList: requestsList
            )
            .navigationTitle("new_request".loc)
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(model.detailType.navigationTitle)
            .font(.headline)
            .opacity(isNavigationTitleVisible ? 1 : 0)
            .animation(.default.speed(2), value: isNavigationTitleVisible)
        }
        if model.detailType.is(\.requestsList) {
          ToolbarItem(placement: .bottomBar) {
            HStack {
              Button {
                model.isNewRequestSheetPresented = true
              } label: {
                HStack {
                  Image(systemName: "plus")
                  Text("additional_questions".loc)
                }
                .font(.body)
              }
              Spacer()
            }
            .tint(model.detailType.color)
          }
        }
        
        ToolbarItem(placement: .primaryAction) {
          Menu {
            Group {
              Menu {
                ForEach(RequestsDetailModel.Ordering.allCases, id: \.self) { ordering in
                  Button {
                    Task { await model.orderingButtonTapped(ordering) }
                  } label: {
                    Text(ordering.localizedTitle)
                    ordering.icon
                  }
                }
              } label: {
                Text("sort_by".loc)
                Text(model.ordering.localizedTitle)
                Image(systemName: "arrow.up.arrow.down")
              }
              
              // Only show this button for non-RequestsList detail types
              if !model.detailType.is(\.requestsList) {
                Button {
                  Task { await model.showCompletedButtonTapped() }
                } label: {
                  Text(model.showCompleted ? "hide_completed".loc : "show_completed".loc)
                  Image(systemName: model.showCompleted ? "eye" : "eye")
                }
              }
            }
            .tint(model.detailType.color)
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
      .tint(ResourcesAsset.Colors.clam.swiftUIColor)
    }
  }
}

extension RequestsDetailModel.DetailType {
  fileprivate var id: String {
    switch self {
    case .all: "all"
    case .completed: "completed"
    case .requestsList(let list): "list_\(list.id)"
    case .scheduled: "scheduled"
    case .today: "today"
    }
  }
  
  fileprivate var navigationTitle: String {
    switch self {
    case .all: "all".loc
    case .completed: "completed".loc
    case .requestsList(let list): list.title
    case .scheduled: "scheduled".loc
    case .today: "today".loc
    }
  }
  
  fileprivate var color: Color {
    switch self {
    case .all: ResourcesAsset.Colors.textPrimary.swiftUIColor
    case .completed: ResourcesAsset.Colors.health.swiftUIColor
    case .requestsList(let list): list.color
    case .scheduled: ResourcesAsset.Colors.energy.swiftUIColor
    case .today: ResourcesAsset.Colors.clam.swiftUIColor
    }
  }
}

struct RequestsDetailPreview: PreviewProvider {
  static var previews: some View {
    let requestsList = try! prepareDependencies {
      $0.defaultDatabase = try appDatabase()
      return try $0.defaultDatabase.read { db in
        (
          try RequestsList.all.fetchOne(db)!,
        )
      }
    }
    
    let detailTypes: [RequestsDetailModel.DetailType] = [
      .all,
      .requestsList(requestsList)
    ]
    
    ForEach(detailTypes, id: \.self) { detailType in
      NavigationStack {
        RequestsDetailView(model: RequestsDetailModel(detailType: detailType))
      }
      .previewDisplayName(detailType.navigationTitle)
    }
  }
}
