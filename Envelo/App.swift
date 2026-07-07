import SwiftUI

@main
struct EnveloApp: App {
    @StateObject private var store = EnveloStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage("envelo_haptics_enabled") private var hapticsEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.light)
                .onAppear {
                    Haptics.enabled = hapticsEnabled
                }
        }
    }
}
