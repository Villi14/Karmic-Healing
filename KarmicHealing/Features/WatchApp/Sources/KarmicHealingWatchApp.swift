//
//   Karmic Healing 2025
//

import SwiftUI
import ComposableArchitecture
import UserNotifications

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
  @State private var notificationDelegate: NotificationDelegate?
  
  var body: some View {
    return WatchBalancingEnergyListView(store: store)
      .onAppear {
        // Load initial state when app appears
        store.send(.onAppear)
        setupNotificationHandling()
      }
  }
  
  private func setupNotificationHandling() {
    // Set up notification delegate to handle taps
    notificationDelegate = NotificationDelegate(store: store)
    UNUserNotificationCenter.current().delegate = notificationDelegate
  }
}

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  private let store: StoreOf<WatchBalancingEnergyList>
  
  init(store: StoreOf<WatchBalancingEnergyList>) {
    self.store = store
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("NotificationDelegate: Received notification tap with userInfo: \(userInfo)")
    
    if let processTitle = userInfo["processTitle"] as? String,
       let currentStep = userInfo["currentStep"] as? Int {
      print("NotificationDelegate: Processing notification - processTitle: '\(processTitle)', currentStep: \(currentStep)")
      print("NotificationDelegate: Sending handleNotificationTap action")
      store.send(.handleNotificationTap(processTitle: processTitle, currentStep: currentStep))
    } else {
      print("NotificationDelegate: Missing required data in userInfo")
      print("NotificationDelegate: processTitle type: \(type(of: userInfo["processTitle"])), value: \(userInfo["processTitle"])")
      print("NotificationDelegate: currentStep type: \(type(of: userInfo["currentStep"])), value: \(userInfo["currentStep"])")
    }
    
    completionHandler()
  }
}
