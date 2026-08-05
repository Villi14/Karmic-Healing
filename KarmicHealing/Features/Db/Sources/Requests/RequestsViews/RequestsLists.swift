import SQLiteData
import SwiftUI
import SwiftUINavigation
import TipKit
import Common
import Resources

@MainActor
@Observable
class RequestsListsModel {
  @ObservationIgnored
  @FetchAll(
    RequestsList
      .order(by: \.position)
      .order(by: \.isCompleted)
      .order(by: \.title),
    animation: .default
  )
  var requestsLists
  
  var destination: Destination?
  var searchRequestsModel = SearchRequestsModel()
  var isHelpPresented = false
  
  @ObservationIgnored
  @Dependency(\.defaultDatabase) private var database
  
  func requestsListTapped(requestsList: RequestsList) {
    destination = .detail(
      RequestsDetailModel(
        detailType: .requestsList(
          requestsList
        )
      )
    )
  }
  
  func onAppear() {
    withErrorReporting {
      try Tips.configure()
    }
  }
  
  func addListButtonTapped() {
    destination = .requestsListForm(RequestsList.Draft())
  }
  
  func helpButtonTapped() {
    isHelpPresented = true
  }
  
  func listDetailsButtonTapped(requestsList: RequestsList) {
    destination = .requestsListForm(RequestsList.Draft(requestsList))
  }
  
  func move(from source: IndexSet, to destination: Int) {
    withErrorReporting {
      try database.write { db in
        var ids = requestsLists.map(\.id)
        ids.move(fromOffsets: source, toOffset: destination)
        try RequestsList
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
  }
  
#if DEBUG
  func seedDatabaseButtonTapped() {
    withErrorReporting {
      try database.write { db in
        try db.seedSampleData()
      }
    }
  }
#endif
  
  @CasePathable
  enum Destination {
    case detail(RequestsDetailModel)
    case requestForm(Request.Draft, requestsList: RequestsList)
    case requestsListForm(RequestsList.Draft)
  }
  
  @Selection
  struct RequestListState: Identifiable {
    var id: RequestsList.ID { requestsList.id }
    var requestsList: RequestsList
  }
}

extension RequestsListsModel {
  var requestsListsArray: [RequestListState] {
    requestsLists.map { requestsList in
      RequestListState(requestsList: requestsList)
    }
  }
}

struct RequestsListsView: View {
  @Bindable var model: RequestsListsModel
  
  var body: some View {
    ZStack {
      AuraBackground(level: .sacral)
      
      VStack(spacing: 0) {
        SearchBar(text: $model.searchRequestsModel.searchText)
        List {
          if model.searchRequestsModel.searchText.isEmpty {
            if model.requestsLists.isEmpty {
              KarmicEmptyStateView(
                iconName: "sparkles",
                title: "requests_empty_title".loc,
                message: "requests_empty_message".loc,
                tone: Spectrum.sacral.color,
                level: .sacral,
                actionTitle: "add_request".loc,
                action: { model.addListButtonTapped() }
              )
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)
              .listRowInsets(EdgeInsets())
            } else {
              requestsSection
            }
          } else {
            searchSection
          }
        }
        .onAppear {
          model.onAppear()
        }
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              model.helpButtonTapped()
            } label: {
              Image(systemName: "questionmark.circle")
                .foregroundStyle(AuraGradient.gradient(for: .sacral))
            }
          }
#if DEBUG
          ToolbarItem(placement: .automatic) {
            Menu {
              Button {
                model.seedDatabaseButtonTapped()
              } label: {
                Text("seed_data".loc)
                  .foregroundStyle(AuraGradient.gradient(for: .sacral))
                
                Image(systemName: "leaf")
                  .foregroundStyle(AuraGradient.gradient(for: .sacral))
              }
            } label: {
              Image(systemName: "ellipsis")
                .foregroundStyle(AuraGradient.gradient(for: .sacral))
            }
          }
#endif
          ToolbarItem(placement: .bottomBar) {
            HStack {
              Button {
                model.addListButtonTapped()
              } label: {
                HStack {
                  Image(systemName: "plus")
                    .foregroundStyle(AuraGradient.gradient(for: .sacral))
                  
                  Text("request".loc)
                    .font(Typography.body)
                    .foregroundStyle(AuraGradient.gradient(for: .sacral))
                }
              }
              
              Spacer()
            }
          }
        }
        .sheet(item: $model.destination.requestForm, id: \.0.id) { request, requestsList in
          NavigationStack {
            RequestFormView(
              request: request,
              requestsList: requestsList,
              title: "new_sub_request".loc
            )
          }
        }
        .sheet(item: $model.destination.requestsListForm) { requestsList in
          NavigationStack {
            RequestsListForm(requestsList: requestsList, title: "request_placeholder".loc)
          }
          .presentationDetents([.large])
        }
        .sheet(isPresented: $model.isHelpPresented) {
          NavigationStack {
            RequestsHelpView()
          }
          .presentationDetents([.large])
        }
        .tint(Spectrum.sacral.color)
        .navigationDestination(item: $model.destination.detail) { detailModel in
          RequestsDetailView(model: detailModel)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, DesignConstants.padding)
        .padding(.top, DesignConstants.padding)
      }
      .karmicContentWidth()
    }
  }
  
  private var requestsSection: some View {
    Section {
      ForEach(model.requestsListsArray) { state in
        RequestsListRow(
          requestsList: state.requestsList,
          onTap: {
            model.requestsListTapped(requestsList: state.requestsList)
          }
        )
      }
    } header: {
      VStack(alignment: .leading, spacing: DesignConstants.spacingSmall) {
        Text("my_requests".loc)
          .font(Typography.title)
          .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)

        // The rows are requests; what hangs under them is the second level.
        Text("subrequests_hint".loc)
          .font(Typography.bodySecondary)
          .foregroundStyle(ResourcesAsset.Colors.textSecondary.swiftUIColor)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .textCase(nil)
      .padding(.top, DesignConstants.paddingNegativeLarge)
      .padding(.horizontal, DesignConstants.paddingSmall)
    }
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
    .listRowInsets(EdgeInsets(
      top: DesignConstants.paddingSmall,
      leading: DesignConstants.paddingMedium,
      bottom: DesignConstants.paddingSmall,
      trailing: DesignConstants.paddingMedium)
    )
  }
  
  private var searchSection: some View {
    SearchRequestsView(
      model: model.searchRequestsModel,
      onRequestTapped: { model.requestsListTapped(requestsList: $0) }
    )
    .listRowBackground(Color.clear)
  }
}

#Preview {
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }
  
  ZStack {
    AuraBackground(level: .sacral)
    NavigationStack {
      RequestsListsView(model: RequestsListsModel())
    }
  }
}
