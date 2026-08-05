import CasePaths
import SQLiteData
import Sharing
import SwiftUI
import SwiftUINavigation
import Common
import Resources

@MainActor
@Observable
class RequestsDetailModel: HashableObject {
  @ObservationIgnored @FetchAll var requestRows: [Row]
  @ObservationIgnored @Shared var showCompleted: Bool
  @ObservationIgnored @Dependency(\.defaultDatabase) private var database
  
  let detailType: DetailType
  var isNewRequestSheetPresented = false
  
  init(detailType: DetailType) {
    self.detailType = detailType
    _showCompleted = Shared(
      wrappedValue: detailType == .completed,
      .appStorage("show_completed_list_\(detailType.id)")
    )
    _requestRows = FetchAll(requestsQuery)
  }
  
  func showCompletedButtonTapped() async {
    $showCompleted.withLock { $0.toggle() }
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
  
  /// Reloads the rows. Internal so tests can await it instead of racing the query that `init`
  /// kicks off.
  func updateQuery() async {
    _ = await withErrorReporting {
      try await $requestRows.load(requestsQuery, animation: .default)
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
      .join(RequestsList.all) { $0.requestsListID.eq($1.id) }
      .select {
        Row.Columns(
          request: $0,
          requestsList: $1,
          notes: $0.inlineNotes.substr(0, 200)
        )
      }
    return query
  }
  
  @CasePathable
  @dynamicMemberLookup
  enum DetailType: Hashable {
    case all
    case completed
    case requestsList(RequestsList)
  }
  
  @Selection
  struct Row: Identifiable {
    var id: Request.ID { request.id }
    let request: Request
    let requestsList: RequestsList
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
      AuraBackground(level: .sacral)
      
      List {
        VStack(alignment: .leading) {
          if let requestsList = model.detailType.requestsList {
            RequestDetailHeader(requestsList: requestsList, color: model.detailType.color)
          } else {
            Text(model.detailType.navigationTitle)
              .font(Typography.title)
              .foregroundStyle(model.detailType.color)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
          navigationTitleHeight = $0
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.bottom, DesignConstants.paddingLarge)
        
        ForEach(model.requestRows) { row in
          RequestRow(
            color: model.detailType.color,
            notes: row.notes,
            request: row.request,
            requestsList: row.requestsList,
            showCompleted: model.showCompleted,
            showsRequest: !model.detailType.is(\.requestsList)
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
              .foregroundStyle(AuraGradient.gradient(for: .sacral))
          }
        }
      }
      .onScrollGeometryChange(for: Bool.self) { geometry in
        geometry.contentOffset.y + geometry.contentInsets.top > navigationTitleHeight
      } action: {
        isNavigationTitleVisible = $1
      }
      .listStyle(.plain)
      .scrollContentBackground(.hidden)
      .karmicContentWidth()
      .sheet(isPresented: $model.isNewRequestSheetPresented) {
        if let requestsList = model.detailType.requestsList {
          NavigationStack {
            RequestFormView(
              request: Request.Draft(requestsListID: requestsList.id),
              requestsList: requestsList,
              title: "new_sub_request".loc
            )
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .principal) {
          Text(model.detailType.navigationTitle)
            .font(Typography.title)
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
                  Text("add_sub_request".loc)
                }
                .font(Typography.body)
              }
              Spacer()
            }
            .tint(model.detailType.color)
          }
        }
        
        // Subrequests keep the order they were written in; only the other detail types
        // hide what is already fulfilled.
        if !model.detailType.is(\.requestsList) {
          ToolbarItem(placement: .primaryAction) {
            Button {
              Task { await model.showCompletedButtonTapped() }
            } label: {
              Text(model.showCompleted ? "hide_completed".loc : "show_completed".loc)
              Image(systemName: "eye")
            }
            .tint(model.detailType.color)
          }
        }
      }
      .tint(Spectrum.sacral.color)
    }
  }
}

extension RequestsDetailModel.DetailType {
  fileprivate var id: String {
    switch self {
    case .all: "all"
    case .completed: "completed"
    case .requestsList(let list): "list_\(list.id)"
    }
  }
  
  fileprivate var navigationTitle: String {
    switch self {
    case .all: "all".loc
    case .completed: "completed".loc
    case .requestsList(let list): list.title
    }
  }
  
  fileprivate var color: Color {
    switch self {
    case .all: ResourcesAsset.Colors.textPrimary.swiftUIColor
    case .completed: ResourcesAsset.Colors.health.swiftUIColor
    case .requestsList(let list): list.color
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
