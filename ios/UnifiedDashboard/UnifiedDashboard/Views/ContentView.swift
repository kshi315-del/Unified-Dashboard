import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: ServerSettings

    var body: some View {
        if settings.isConfigured {
            MainTabView()
        } else {
            SettingsView(isInitialSetup: true)
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var settings: ServerSettings

    var body: some View {
        TabView {
            OverviewView()
                .tabItem {
                    Label("Overview", systemImage: "chart.bar.fill")
                }

            CapitalView()
                .tabItem {
                    Label("Capital", systemImage: "dollarsign.circle.fill")
                }

            BotDashboardView()
                .tabItem {
                    Label("Dashboards", systemImage: "square.grid.2x2.fill")
                }

            SettingsView(isInitialSetup: false)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.blue)
    }
}
