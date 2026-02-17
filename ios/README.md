# Unified Dashboard — iOS App

A native SwiftUI iOS client for the Unified Dashboard portal. Connects to
your existing Flask backend and provides all dashboard functionality from
your iPhone or iPad.

## Features

- **Overview Tab** — Real-time portfolio P&L and bot health cards with
  5-second auto-refresh (matches the web dashboard)
- **Capital Tab** — View allocations, allocate capital, transfer funds
  between bots, and browse transfer history
- **Bot Dashboards** — Embedded WKWebView for each bot's native dashboard,
  proxied through the portal (just like the web version's iframes)
- **Settings** — Configure server URL and optional Basic Auth credentials,
  with a connection test button

## Requirements

- Xcode 15+
- iOS 17.0+
- Swift 5.9+
- A running Unified Dashboard backend (the Flask server)

## Getting Started

1. Open `ios/UnifiedDashboard/UnifiedDashboard.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run (Cmd+R)
4. On first launch, enter your portal server URL (e.g. `http://192.168.1.100:8080`)
5. Optionally enter Basic Auth credentials if your portal has `PORTAL_USER`/`PORTAL_PASS` set
6. Tap "Test Connection" to verify, then you're in

## Architecture

```
UnifiedDashboard/
├── UnifiedDashboardApp.swift   # App entry point
├── Models/
│   ├── Bot.swift               # /api/overview response models
│   └── Capital.swift           # /api/capital response & request models
├── Networking/
│   ├── APIClient.swift         # HTTP client (URLSession → Flask backend)
│   └── ServerSettings.swift    # Persisted server config (UserDefaults)
├── Views/
│   ├── ContentView.swift       # Root view (setup vs main tabs)
│   ├── OverviewView.swift      # Portfolio overview with polling
│   ├── CapitalView.swift       # Capital management (CRUD + history)
│   ├── BotDashboardView.swift  # WKWebView per-bot proxy dashboards
│   ├── SettingsView.swift      # Server URL & auth configuration
│   └── Components/
│       ├── BotCardView.swift   # Individual bot status card
│       └── CapitalCardView.swift # Capital account card
└── Utilities/
    └── Formatters.swift        # Dollar formatting, hex colors, timestamps
```

## How It Works

The iOS app is a **thin client** that talks to your existing Flask backend.
It does NOT connect to bots or Kalshi directly — all data flows through
the portal's API endpoints:

| App Feature     | Backend Endpoint          |
|-----------------|---------------------------|
| Overview tab    | `GET /api/overview`       |
| Capital tab     | `GET /api/capital`        |
| Allocate        | `POST /api/capital/allocate` |
| Transfer        | `POST /api/capital/transfer` |
| Remove alloc    | `DELETE /api/capital/{id}` |
| Transfer history| `GET /api/capital/transfers` |
| Bot dashboards  | `GET /bot/{id}/` (WebView) |

## Network Notes

- The backend must be reachable from the iOS device (same WiFi, VPN, or
  public endpoint)
- `Info.plist` includes `NSAllowsLocalNetworking` for `http://` access to
  local servers
- Bot dashboard WebViews pass Basic Auth headers if configured
