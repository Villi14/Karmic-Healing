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

  let detailType: DetailType
  var isNewRequestSheetPresented = false

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

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
    }
  }

  private var requestsQuery: some StructuredQueriesCore.Statement<Row> {
    let query =
    Request
      .where {
        if !showCompleted {
          !$0.isCompleted
        }
      }
      .order { $0.isCompleted }
      .order {
        switch ordering {
        case .dueDate: $0.dueDate.asc(nulls: .last)
        case .priority: ($0.priority.desc(), $0.isFlagged.desc())
        case .title: $0.title
        }
      }
      .where { request in
        switch detailType {
        case .all: !request.isCompleted
        case .completed: request.isCompleted
        case .flagged: request.isFlagged
        case .requestsList(let list): request.requestsListID.eq(list.id)
        case .scheduled: request.isScheduled
        case .today: request.isToday
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
        return String(localized: "due_date", bundle: .main)
      case .priority:
        return String(localized: "priority", bundle: .main)
      case .title:
        return String(localized: "title", bundle: .main)
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
    case flagged
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
      LinearGradient(
        gradient: Gradient(colors: [
          ResourcesAsset.Colors.clam.swiftUIColor.opacity(0.1),
          ResourcesAsset.Colors.background.swiftUIColor
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      List {
        VStack(alignment: .leading) {
          GeometryReader { proxy in
            Text(model.detailType.navigationTitle)
              .font(.system(.largeTitle, design: .rounded, weight: .bold))
              .foregroundStyle(model.detailType.color)
              .onAppear { navigationTitleHeight = proxy.size.height }
          }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .padding(.bottom, 16)

        ForEach(model.requestRows) { row in
          RequestRow(
            color: model.detailType.color,
            isPastDue: row.isPastDue,
            notes: row.notes,
            request: row.request,
            requestsList: row.requestsList,
            showCompleted: model.showCompleted
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
              .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
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
            .navigationTitle(String(localized: "new_request", bundle: .main))
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
                  Text(String(localized: "request", bundle: .main))
                }
                .font(.title3)
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
                Text(String(localized: "sort_by", bundle: .main))
                Text(model.ordering.localizedTitle)
                Image(systemName: "arrow.up.arrow.down")
              }

              Button {
                Task { await model.showCompletedButtonTapped() }
              } label: {
                Text(model.showCompleted ? String(localized: "hide_completed", bundle: .main) : String(localized: "show_completed", bundle: .main))
                Image(systemName: model.showCompleted ? "eye" : "eye")
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
    case .flagged: "flagged"
    case .requestsList(let list): "list_\(list.id)"
    case .scheduled: "scheduled"
    case .today: "today"
    }
  }

  fileprivate var navigationTitle: String {
    switch self {
    case .all: String(localized: "all", bundle: .main)
    case .completed: String(localized: "completed", bundle: .main)
    case .flagged: String(localized: "flagged", bundle: .main)
    case .requestsList(let list): list.title
    case .scheduled: String(localized: "scheduled", bundle: .main)
    case .today: String(localized: "today", bundle: .main)
    }
  }

  fileprivate var color: Color {
    switch self {
    case .all: ResourcesAsset.Colors.textPrimary.swiftUIColor
    case .completed: ResourcesAsset.Colors.health.swiftUIColor
    case .flagged: ResourcesAsset.Colors.friendly.swiftUIColor
    case .requestsList(let list): list.color
    case .scheduled: ResourcesAsset.Colors.error.swiftUIColor
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
