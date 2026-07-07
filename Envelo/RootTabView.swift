import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            EntryListView()
                .tabItem {
                    Label("Home", systemImage: "envelope.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(EVTheme.coral)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(EVTheme.card)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(EnveloStore())
        .environmentObject(PurchaseManager())
}
