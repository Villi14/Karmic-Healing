import ComposableArchitecture

@Reducer
public struct Db {
  public init() {}
  
  @ObservableState
  public struct State: Equatable {
    public init() {}
  }
  
  public enum Action: Equatable {}
  
  public var body: some ReducerOf<Self> {
    Reduce { _, _ in .none }
  }
} 
 