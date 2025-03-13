//
// Karmic Healing 2025
//

import Dependencies
import Foundation

extension DependencyValues {
  public var performance: PerformanceClient {
    get { self[PerformanceClient.self] }
    set { self[PerformanceClient.self] = newValue }
  }
}

public struct PerformanceClient {
  public var startTrace: @Sendable (String) -> PerformanceTrace
  public var recordMetric: @Sendable (String, String, Double) -> Void
  public var recordError: @Sendable (Error, String?) -> Void
  
  public init(
    startTrace: @Sendable @escaping (String) -> PerformanceTrace,
    recordMetric: @Sendable @escaping (String, String, Double) -> Void,
    recordError: @Sendable @escaping (Error, String?) -> Void
  ) {
    self.startTrace = startTrace
    self.recordMetric = recordMetric
    self.recordError = recordError
  }
}

extension PerformanceClient: DependencyKey {
  public static let liveValue: Self = {
    return Self(
      startTrace: { name in
        PerformanceTrace(name: name)
      },
      recordMetric: { traceName, metricName, value in
        print("📈 Performance: \(traceName) - \(metricName): \(value)")
      },
      recordError: { error, context in
        print("❌ Error: \(error.localizedDescription) - Context: \(context ?? "none")")
      }
    )
  }()
  
  public static let testValue: Self = {
    return Self(
      startTrace: { _ in PerformanceTrace(name: "test") },
      recordMetric: { _, _, _ in },
      recordError: { _, _ in }
    )
  }()
}

public class PerformanceTrace {
  private let name: String
  private let startTime: CFAbsoluteTime
  
  public init(name: String) {
    self.name = name
    self.startTime = CFAbsoluteTimeGetCurrent()
  }
  
  public func stop() {
    let duration = CFAbsoluteTimeGetCurrent() - startTime
    print("📈 Trace \(name) completed in \(duration)s")
  }
  
  public func addMetric(_ name: String, value: Double) {
    print("📈 Trace \(self.name) - \(name): \(value)")
  }
}

// MARK: - Convenience methods
extension PerformanceClient {
  public func measure<T>(_ name: String, operation: () throws -> T) rethrows -> T {
    let trace = startTrace(name)
    defer { trace.stop() }
    return try operation()
  }
  
  public func measureAsync<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
    let trace = startTrace(name)
    defer { trace.stop() }
    return try await operation()
  }
} 