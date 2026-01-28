# FlowMeet React Dashboard

A modern, comprehensive dashboard for FlowMeet with elegant design and smooth animations.

## Features

- **Real-time Meeting Timeline** - Visual timeline showing today's schedule
- **Stats Overview** - Key metrics at a glance
- **Audio Visualization** - Live waveform display during recordings
- **Activity Feed** - Recent events and updates
- **Meeting Management** - View and join upcoming meetings
- **AI-Generated Notes** - Access meeting summaries and action items

## Design Philosophy

This dashboard follows a **modern minimalist** aesthetic with:
- Refined typography using Crimson Pro (display) and DM Sans (body)
- Monochrome color palette with strategic accent colors
- Smooth animations and micro-interactions
- Clean, spacious layouts with intentional negative space
- Production-grade attention to detail

## Installation

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build
```

## Integration with macOS App

### Step 1: Add WKWebView to your SwiftUI app

Create a new file `DashboardView.swift`:

```swift
import SwiftUI
import WebKit

struct DashboardView: View {
    @EnvironmentObject var meetingListViewModel: MeetingListViewModel
    @StateObject private var webViewModel = WebViewModel()
    
    var body: some View {
        WebView(viewModel: webViewModel)
            .onAppear {
                webViewModel.loadLocalHTML()
                webViewModel.setupMessageHandlers(meetingViewModel: meetingListViewModel)
            }
    }
}

class WebViewModel: ObservableObject {
    var webView: WKWebView?
    
    func loadLocalHTML() {
        // Load the built React app from your bundle
        guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "dashboard/dist"),
              let htmlURL = URL(fileURLWithPath: htmlPath) else {
            print("Could not find HTML file")
            return
        }
        
        webView?.loadFileURL(htmlURL, allowingReadAccessTo: htmlURL.deletingLastPathComponent())
    }
    
    func setupMessageHandlers(meetingViewModel: MeetingListViewModel) {
        // Handle messages from React
        // Implementation details below
    }
    
    func sendMeetingsUpdate(_ meetings: [Meeting]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        if let jsonData = try? encoder.encode(meetings),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let script = """
            window.postMessage({
                type: 'updateMeetings',
                data: { meetings: \(jsonString) }
            }, '*');
            """
            webView?.evaluateJavaScript(script)
        }
    }
}

struct WebView: NSViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        // Add message handlers
        config.userContentController.add(context.coordinator, name: "joinMeeting")
        config.userContentController.add(context.coordinator, name: "showMeetingDetail")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        viewModel.webView = webView
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any] else { return }
            
            switch message.name {
            case "joinMeeting":
                if let meetingId = body["meetingId"] as? String {
                    // Handle join meeting
                    print("Join meeting: \\(meetingId)")
                }
            case "showMeetingDetail":
                if let meetingId = body["meetingId"] as? String {
                    // Handle show detail
                    print("Show meeting detail: \\(meetingId)")
                }
            default:
                break
            }
        }
    }
}
```

### Step 2: Build the React Dashboard

```bash
# Build the dashboard
npm run build

# Copy the dist folder to your Xcode project
# Add it to your app's bundle in Xcode
# Make sure "Create folder references" is selected when adding
```

### Step 3: Update your FlowMeetApp.swift

```swift
@main
struct FlowMeetApp: App {
    @StateObject private var meetingListViewModel = MeetingListViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some Scene {
        WindowGroup {
            DashboardView()  // Use the new dashboard view
                .environmentObject(meetingListViewModel)
                .environmentObject(settingsViewModel)
        }
        // ... rest of your app configuration
    }
}
```

### Step 4: Send Data from Swift to React

```swift
// In your MeetingListViewModel, when meetings update:
func syncMeetings() {
    // After fetching meetings
    NotificationCenter.default.post(
        name: .meetingsDidUpdate,
        object: self.meetings
    )
}

// In DashboardView:
.onReceive(NotificationCenter.default.publisher(for: .meetingsDidUpdate)) { notification in
    if let meetings = notification.object as? [Meeting] {
        webViewModel.sendMeetingsUpdate(meetings)
    }
}
```

## File Structure

```
dashboard/
├── src/
│   ├── components/
│   │   ├── StatsCard/
│   │   ├── MeetingCard/
│   │   ├── Timeline/
│   │   ├── AudioVisualizer/
│   │   └── ActivityFeed/
│   ├── pages/
│   │   └── Dashboard.tsx
│   ├── types/
│   │   └── index.ts
│   ├── utils/
│   │   └── helpers.ts
│   ├── data/
│   │   └── mockData.ts
│   ├── styles/
│   │   └── globals.css
│   ├── App.tsx
│   └── main.tsx
├── index.html
├── package.json
├── vite.config.js
└── tsconfig.json
```

## Customization

### Colors

Edit `src/styles/globals.css` to change the color scheme:

```css
:root {
  --color-accent-primary: #2563eb;  /* Primary blue */
  --color-accent-secondary: #0ea5e9; /* Secondary blue */
  /* ... other colors */
}
```

### Fonts

The dashboard uses:
- **Crimson Pro** for headings (serif)
- **DM Sans** for body text (sans-serif)

To change fonts, update the Google Fonts import in `globals.css`.

### Animations

All animations use Framer Motion. Adjust timing and easing in individual components or the global CSS variables.

## Development Notes

- The dashboard uses mock data by default
- Message passing between React and Swift is set up via `window.webkit.messageHandlers`
- All components are fully typed with TypeScript
- Responsive design works down to mobile sizes

## License

MIT
