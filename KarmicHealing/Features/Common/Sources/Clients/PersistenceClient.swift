//
// Karmic Healing 2025
//

import Dependencies
import Foundation

extension DependencyValues {
  public var persistence: PersistenceClient {
    get { self[PersistenceClient.self] }
    set { self[PersistenceClient.self] = newValue }
  }
}

public struct PersistenceClient {
  public var saveRequests: @Sendable ([RequestItem]) async throws -> Void
  public var loadRequests: @Sendable () async throws -> [RequestItem]
  public var saveCompletedSteps: @Sendable (String, Int) async throws -> Void
  public var loadCompletedSteps: @Sendable (String) async throws -> Int
  public var clearAllData: @Sendable () async throws -> Void
  
  public init(
    saveRequests: @Sendable @escaping ([RequestItem]) async throws -> Void,
    loadRequests: @Sendable @escaping () async throws -> [RequestItem],
    saveCompletedSteps: @Sendable @escaping (String, Int) async throws -> Void,
    loadCompletedSteps: @Sendable @escaping (String) async throws -> Int,
    clearAllData: @Sendable @escaping () async throws -> Void
  ) {
    self.saveRequests = saveRequests
    self.loadRequests = loadRequests
    self.saveCompletedSteps = saveCompletedSteps
    self.loadCompletedSteps = loadCompletedSteps
    self.clearAllData = clearAllData
  }
}

extension PersistenceClient: DependencyKey {
  public static let liveValue: Self = {
    return Self(
      saveRequests: { requests in
        let data = try JSONEncoder().encode(requests)
        UserDefaults.standard.set(data, forKey: "saved_requests")
      },
      loadRequests: {
        guard let data = UserDefaults.standard.data(forKey: "saved_requests") else {
          return []
        }
        return try JSONDecoder().decode([RequestItem].self, from: data)
      },
      saveCompletedSteps: { type, steps in
        UserDefaults.standard.set(steps, forKey: "completed_steps_\(type)")
      },
      loadCompletedSteps: { type in
        UserDefaults.standard.integer(forKey: "completed_steps_\(type)")
      },
      clearAllData: {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
      }
    )
  }()
  
  public static let testValue: Self = {
    return Self(
      saveRequests: { _ in },
      loadRequests: { [] },
      saveCompletedSteps: { _, _ in },
      loadCompletedSteps: { _ in 0 },
      clearAllData: { }
    )
  }()
}

// MARK: - RequestItem for persistence
public struct RequestItem: Equatable, Identifiable, Codable {
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