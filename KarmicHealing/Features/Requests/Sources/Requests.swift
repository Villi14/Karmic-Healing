//
//   Karmic Healing 2025
//

import Foundation
import ComposableArchitecture
import Common

@Reducer
public struct Requests {
  
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    public var requests: [RequestItem]
    public var isLoading: Bool
    
    public init(requests: [RequestItem] = [], isLoading: Bool = false) {
      self.requests = requests
      self.isLoading = isLoading
    }
  }
  
  public enum Action: Equatable {
    case loadRequests
    case requestsLoaded([RequestItem])
    case addRequest(RequestItem)
    case deleteRequest(RequestItem.ID)
    case toggleRequest(RequestItem.ID)
  }
  
  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .loadRequests:
        state.isLoading = true
        // Тут можна додати завантаження з бази даних або API
        return .run { send in
          // Симуляція завантаження
          try await Task.sleep(for: .seconds(1))
          await send(.requestsLoaded([
            .init(title: "Peace and Harmony", description: "Request for inner peace", isCompleted: false),
            .init(title: "Healing", description: "Request for physical healing", isCompleted: true),
            .init(title: "Guidance", description: "Request for spiritual guidance", isCompleted: false)
          ]))
        }
        
      case let .requestsLoaded(requests):
        state.requests = requests
        state.isLoading = false
        return .none
        
      case let .addRequest(request):
        state.requests.append(request)
        return .none
        
      case let .deleteRequest(id):
        state.requests.removeAll { $0.id == id }
        return .none
        
      case let .toggleRequest(id):
        if let index = state.requests.firstIndex(where: { $0.id == id }) {
          state.requests[index].isCompleted.toggle()
        }
        return .none
      }
    }
  }
}

public struct RequestItem: Equatable, Identifiable {
  public let id: UUID
  public let title: String
  public let description: String
  public var isCompleted: Bool
  public let createdAt: Date
  
  public init(
    id: UUID = UUID(),
    title: String,
    description: String,
    isCompleted: Bool = false,
    createdAt: Date = Date()
  ) {
    self.id = id
    self.title = title
    self.description = description
    self.isCompleted = isCompleted
    self.createdAt = createdAt
  }
}
