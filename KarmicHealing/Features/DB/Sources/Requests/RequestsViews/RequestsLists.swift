import SharingGRDB
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
    searchRequestsModel.searchText = ""
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
      BgWithGradientView()
      
      VStack(spacing: 0) {
        SearchBar(text: $model.searchRequestsModel.searchText)
        List {
          if model.searchRequestsModel.searchText.isEmpty {
            requestsSection
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
                .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
            }
          }
#if DEBUG
          ToolbarItem(placement: .automatic) {
            Menu {
              Button {
                model.seedDatabaseButtonTapped()
              } label: {
                Text("seed_data".loc())
                  .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
                
                Image(systemName: "leaf")
                  .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
              }
            } label: {
              Image(systemName: "ellipsis")
                .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
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
                    .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
                  
                  Text("request".loc())
                    .font(.body)
                    .foregroundStyle(ResourcesAsset.Colors.clam.swiftUIColor)
                }
              }
              
              Spacer()
            }
          }
        }
        .sheet(item: $model.destination.requestForm, id: \.0.id) { request, requestsList in
          NavigationStack {
            RequestFormView(request: request, requestsList: requestsList)
              .navigationTitle("new_request".loc())
          }
        }
        .sheet(item: $model.destination.requestsListForm) { requestsList in
          NavigationStack {
            RequestsListForm(requestsList: requestsList)
              .navigationTitle("new_list".loc())
          }
          .presentationDetents([.medium])
        }
        .sheet(isPresented: $model.isHelpPresented) {
          NavigationStack {
            RequestsHelpView()
          }
          .presentationDetents([.large])
        }
        .tint(ResourcesAsset.Colors.clam.swiftUIColor)
        .navigationDestination(item: $model.destination.detail) { detailModel in
          RequestsDetailView(model: detailModel)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, DesignConstants.padding)
        .padding(.top, DesignConstants.padding)
      }
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
      Text("my_requests".loc())
        .font(.system(.headline, design: .rounded, weight: .bold))
        .foregroundStyle(ResourcesAsset.Colors.textPrimary.swiftUIColor)
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
    SearchRequestsView(model: model.searchRequestsModel)
      .listRowBackground(Color.clear)
  }
}

#Preview {
  let _ = try! prepareDependencies {
    $0.defaultDatabase = try appDatabase()
  }
  
  ZStack {
    BgWithGradientView()
    NavigationStack {
      RequestsListsView(model: RequestsListsModel())
    }
  }
}
