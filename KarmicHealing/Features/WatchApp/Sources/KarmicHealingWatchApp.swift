//
//   Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import OSLog

@main
struct KarmicHealingWatchApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @State private var store = StoreOf<WatchBalancingEnergyList>(
    initialState: .init(),
    reducer: {
      WatchBalancingEnergyList()
    }
  )

  // The watch posts no notifications of its own: a session runs only while the app is open, so
  // there is nothing to deliver once it is closed, and no tap to route back into a session.
  var body: some View {
    WatchBalancingEnergyListView(store: store)
      .onAppear { store.send(.onAppear) }
  }
}
