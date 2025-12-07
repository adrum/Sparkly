# Sparkly

A native macOS app for managing and installing simulator/emulator builds. Think "Sparkle for simulators" — a polished, native update client for development builds targeting iOS Simulators and Android Emulators.

## Project Overview

Sparkly connects to a JSON index file containing references to Sparkle-format appcast feeds, fetches available builds, downloads/caches them locally, and installs them into iOS Simulators or Android Emulators. It also provides basic device management: launching, booting, and monitoring simulators and emulators.

## Tech Stack

- **Language:** Swift 6 (strict concurrency)
- **UI Framework:** SwiftUI (macOS 14+ / Sonoma)
- **Networking:** async/await with URLSession
- **XML Parsing:** Foundation XMLParser for appcast feeds
- **Persistence:** SwiftData for build history and cache metadata
- **Architecture:** MVVM with Observable framework (`@Observable`, `@Environment`)

## Project Structure

```
Sparkly/
├── App/
│   ├── SparklyApp.swift         # App entry point
│   └── AppDelegate.swift         # Menu bar, lifecycle hooks
├── Features/
│   ├── BuildList/                # Remote build browsing
│   │   ├── BuildListView.swift
│   │   ├── BuildListViewModel.swift
│   │   └── BuildRowView.swift
│   ├── Downloads/                # Download queue & progress
│   │   ├── DownloadManager.swift
│   │   ├── DownloadsView.swift
│   │   └── DownloadTask.swift
│   ├── Devices/                  # Simulator/Emulator management
│   │   ├── DeviceListView.swift
│   │   ├── DeviceManager.swift
│   │   ├── SimulatorDevice.swift
│   │   └── EmulatorDevice.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── SourceConfiguration.swift
├── Services/
│   ├── AppIndex/                 # Index + Appcast fetching
│   │   ├── AppIndexService.swift
│   │   ├── AppcastParser.swift
│   │   ├── AppIndex.swift
│   │   └── AppcastItem.swift
│   ├── Simulator/                # iOS Simulator control
│   │   ├── SimctlService.swift
│   │   └── SimulatorInstaller.swift
│   ├── Emulator/                 # Android Emulator control
│   │   ├── ADBService.swift
│   │   ├── AVDManager.swift
│   │   └── EmulatorInstaller.swift
│   └── Cache/
│       ├── BuildCache.swift
│       └── CachePolicy.swift
├── Models/
│   ├── App.swift                 # App definition from index
│   ├── Build.swift               # Build from appcast item
│   ├── Device.swift              # Device protocol & types
│   └── Platform.swift
├── Shared/
│   ├── Extensions/
│   ├── Components/               # Reusable SwiftUI views
│   └── Utilities/
└── Resources/
    └── Assets.xcassets
```

## Feed Architecture

### Sparkly Index Format (JSON)

A proprietary JSON index file that lists apps and their appcast URLs:

```json
{
  "version": 1,
  "title": "My Team's Simulator Builds",
  "apps": [
    {
      "id": "com.example.myapp",
      "name": "MyApp",
      "icon": "https://builds.example.com/icons/myapp.png",
      "platform": "ios",
      "appcastURL": "https://builds.example.com/myapp/appcast.xml"
    },
    {
      "id": "com.example.myapp.android",
      "name": "MyApp",
      "icon": "https://builds.example.com/icons/myapp.png",
      "platform": "android",
      "appcastURL": "https://builds.example.com/myapp-android/appcast.xml"
    },
    {
      "id": "com.example.otherapp",
      "name": "OtherApp",
      "icon": "https://builds.example.com/icons/otherapp.png",
      "platform": "ios",
      "appcastURL": "https://builds.example.com/otherapp/appcast.xml"
    }
  ]
}
```

#### Index Model

```swift
struct AppIndex: Codable, Sendable {
    let version: Int
    let title: String?
    let apps: [AppEntry]
}

struct AppEntry: Codable, Sendable, Identifiable {
    let id: String  // Bundle ID
    let name: String
    let icon: URL?
    let platform: Platform
    let appcastURL: URL
}

enum Platform: String, Codable, Sendable {
    case ios
    case android
}
```

### Sparkle Appcast Format (XML)

Each app has a standard Sparkle appcast feed. Sparkly parses these to get available builds:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>MyApp Simulator Builds</title>
    <link>https://builds.example.com/myapp</link>
    <description>Simulator builds for MyApp</description>
    <language>en</language>
    
    <item>
      <title>Version 1.2.3 (456)</title>
      <pubDate>Wed, 15 Jan 2025 10:30:00 +0000</pubDate>
      <sparkle:version>456</sparkle:version>
      <sparkle:shortVersionString>1.2.3</sparkle:shortVersionString>
      <description><![CDATA[
        <h2>What's New</h2>
        <ul>
          <li>New feature X</li>
          <li>Bug fix for Y</li>
        </ul>
      ]]></description>
      <enclosure 
        url="https://builds.example.com/myapp/MyApp-1.2.3.app.zip"
        length="45000000"
        type="application/octet-stream"
        sparkle:edSignature="BASE64_ED_SIGNATURE_HERE" />
    </item>
    
    <item>
      <title>Version 1.2.2 (450)</title>
      <pubDate>Mon, 10 Jan 2025 14:00:00 +0000</pubDate>
      <sparkle:version>450</sparkle:version>
      <sparkle:shortVersionString>1.2.2</sparkle:shortVersionString>
      <enclosure 
        url="https://builds.example.com/myapp/MyApp-1.2.2.app.zip"
        length="44500000"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
```

### Appcast Parser

```swift
final class AppcastParser: NSObject, XMLParserDelegate, Sendable {
    
    func parse(data: Data) throws -> [AppcastItem] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        guard parser.parse() else {
            throw SparklyError.appcastParsingFailed(parser.parserError)
        }
        
        return items
    }
    
    // XMLParserDelegate implementation...
}

struct AppcastItem: Sendable, Identifiable {
    var id: String { "\(bundleVersion)-\(shortVersion)" }
    
    let title: String
    let pubDate: Date
    let bundleVersion: String      // sparkle:version (build number)
    let shortVersion: String       // sparkle:shortVersionString
    let releaseNotes: String?      // HTML description
    let enclosureURL: URL
    let enclosureLength: Int64?
    let edSignature: String?       // sparkle:edSignature
}
```

## Architecture Guidelines

### MVVM with @Observable

```swift
@Observable
final class BuildListViewModel {
    private(set) var apps: [AppWithBuilds] = []
    private(set) var isLoading = false
    var errorMessage: String?
    
    private let indexService: AppIndexService
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let index = try await indexService.fetchIndex()
            apps = try await indexService.fetchAllAppcasts(for: index)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct AppWithBuilds: Identifiable {
    let app: AppEntry
    let builds: [AppcastItem]
    
    var id: String { app.id }
}
```

### App Index Service

```swift
actor AppIndexService {
    private let indexURL: URL
    private let session: URLSession
    private var cachedIndex: AppIndex?
    
    init(indexURL: URL, session: URLSession = .shared) {
        self.indexURL = indexURL
        self.session = session
    }
    
    func fetchIndex() async throws -> AppIndex {
        let (data, _) = try await session.data(from: indexURL)
        let index = try JSONDecoder().decode(AppIndex.self, from: data)
        cachedIndex = index
        return index
    }
    
    func fetchAppcast(for app: AppEntry) async throws -> [AppcastItem] {
        let (data, _) = try await session.data(from: app.appcastURL)
        return try AppcastParser().parse(data: data)
    }
    
    func fetchAllAppcasts(for index: AppIndex) async throws -> [AppWithBuilds] {
        try await withThrowingTaskGroup(of: AppWithBuilds.self) { group in
            for app in index.apps {
                group.addTask {
                    let builds = try await self.fetchAppcast(for: app)
                    return AppWithBuilds(app: app, builds: builds)
                }
            }
            
            var results: [AppWithBuilds] = []
            for try await appWithBuilds in group {
                results.append(appWithBuilds)
            }
            return results.sorted { $0.app.name < $1.app.name }
        }
    }
}
```

### Actor-Based Download Manager

```swift
actor DownloadManager {
    private var activeTasks: [String: DownloadTask] = [:]
    private let cache: BuildCache
    
    func download(_ item: AppcastItem, for app: AppEntry) async throws -> URL {
        // Check cache first
        if let cached = await cache.cachedPath(for: item, app: app) {
            return cached
        }
        
        let taskID = "\(app.id)-\(item.bundleVersion)"
        
        let task = DownloadTask(url: item.enclosureURL)
        activeTasks[taskID] = task
        defer { activeTasks.removeValue(forKey: taskID) }
        
        let tempURL = try await task.start()
        return try await cache.store(tempURL, for: item, app: app)
    }
    
    func progress(for app: AppEntry, item: AppcastItem) -> AsyncStream<Double> {
        // Return progress stream for UI
    }
    
    func cancel(app: AppEntry, item: AppcastItem) {
        let taskID = "\(app.id)-\(item.bundleVersion)"
        activeTasks[taskID]?.cancel()
    }
}
```

## Key Implementation Details

### iOS Simulator Integration (simctl)

Use `xcrun simctl` for all simulator operations:

```swift
struct SimctlService {
    func listDevices() async throws -> [SimulatorDevice] {
        let output = try await shell("xcrun", "simctl", "list", "devices", "--json")
        return try JSONDecoder().decode(SimctlDeviceList.self, from: output).devices
    }
    
    func boot(udid: String) async throws {
        try await shell("xcrun", "simctl", "boot", udid)
    }
    
    func install(udid: String, appPath: URL) async throws {
        try await shell("xcrun", "simctl", "install", udid, appPath.path)
    }
    
    func launch(udid: String, bundleID: String) async throws {
        try await shell("xcrun", "simctl", "launch", udid, bundleID)
    }
}
```

### Android Emulator Integration (adb + avdmanager)

```swift
struct ADBService {
    private let adbPath: String  // Usually ~/Library/Android/sdk/platform-tools/adb
    
    func listDevices() async throws -> [EmulatorDevice] {
        let output = try await shell(adbPath, "devices", "-l")
        return parseDeviceList(output)
    }
    
    func install(serial: String, apkPath: URL) async throws {
        try await shell(adbPath, "-s", serial, "install", "-r", apkPath.path)
    }
}

struct AVDManager {
    private let emulatorPath: String  // ~/Library/Android/sdk/emulator/emulator
    
    func listAVDs() async throws -> [String] {
        let output = try await shell(emulatorPath, "-list-avds")
        return output.split(separator: "\n").map(String.init)
    }
    
    func launch(avdName: String) async throws {
        // Launch detached
        try await shell(emulatorPath, "-avd", avdName, "-no-snapshot-load")
    }
}
```

### Build Cache Strategy

```swift
actor BuildCache {
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 10_000_000_000  // 10 GB
    
    func cachedPath(for item: AppcastItem, app: AppEntry) -> URL? {
        let path = cacheDirectory
            .appending(path: app.id)
            .appending(path: "\(item.shortVersion)-\(item.bundleVersion)")
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }
    
    func store(_ data: URL, for item: AppcastItem, app: AppEntry) async throws -> URL {
        try await evictIfNeeded()
        
        let destination = cacheDirectory
            .appending(path: app.id)
            .appending(path: "\(item.shortVersion)-\(item.bundleVersion)")
        
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(at: data, to: destination)
        
        return destination
    }
    
    private func evictIfNeeded() async throws {
        // LRU eviction based on access date
    }
}
```

### Installation Flow

```swift
struct InstallationService {
    private let simctl: SimctlService
    private let adb: ADBService
    private let downloadManager: DownloadManager
    private let cache: BuildCache
    
    func install(
        _ item: AppcastItem,
        for app: AppEntry,
        on device: any DeviceProtocol
    ) async throws {
        // 1. Download or retrieve from cache
        let archivePath = try await downloadManager.download(item, for: app)
        
        // 2. Extract if needed
        let installablePath = try await extractIfNeeded(archivePath, platform: app.platform)
        
        // 3. Install to device
        switch device {
        case let simulator as SimulatorDevice:
            try await simctl.install(udid: simulator.udid, appPath: installablePath)
            try await simctl.launch(udid: simulator.udid, bundleID: app.id)
            
        case let emulator as EmulatorDevice:
            try await adb.install(serial: emulator.serial, apkPath: installablePath)
            
        default:
            throw SparklyError.unsupportedDevice
        }
    }
    
    private func extractIfNeeded(_ archive: URL, platform: Platform) async throws -> URL {
        // Handle .zip -> .app extraction for iOS
        // APKs typically don't need extraction
    }
}
```

## Code Conventions

### Swift Style

- Use Swift 6 strict concurrency; mark types `Sendable` where appropriate
- Prefer `async/await` over Combine for async operations
- Use `@Observable` macro for ViewModels (not `ObservableObject`)
- Avoid force unwrapping; use guard/if-let
- Keep views thin; business logic goes in ViewModels/Services

### Naming

- ViewModels: `[Feature]ViewModel` (e.g., `BuildListViewModel`)
- Services: `[Domain]Service` or `[Domain]Manager` (e.g., `SimctlService`, `DownloadManager`)
- Protocols: Descriptive names, `Protocol` suffix only for disambiguation
- Files match primary type name

### Error Handling

```swift
enum SparklyError: LocalizedError {
    case indexFetchFailed(underlying: Error)
    case appcastParsingFailed(Error?)
    case simulatorNotFound(String)
    case installationFailed(String, underlying: Error)
    case downloadFailed(URL, underlying: Error)
    case adbNotFound
    case emulatorNotFound(String)
    case unsupportedDevice
    case extractionFailed(URL)
    
    var errorDescription: String? {
        switch self {
        case .indexFetchFailed(let error):
            return "Failed to fetch app index: \(error.localizedDescription)"
        case .appcastParsingFailed(let error):
            return "Failed to parse appcast: \(error?.localizedDescription ?? "Unknown error")"
        case .simulatorNotFound(let udid):
            return "Simulator \(udid) not found"
        // ...
        }
    }
}
```

### SwiftUI Patterns

Use `@Environment` for shared services:

```swift
@main
struct SparklyApp: App {
    @State private var indexService = AppIndexService(
        indexURL: URL(string: "https://builds.example.com/sparkley-index.json")!
    )
    @State private var downloadManager = DownloadManager()
    @State private var deviceManager = DeviceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(indexService)
                .environment(downloadManager)
                .environment(deviceManager)
        }
        .commands {
            SparklyCommands()
        }
        
        Settings {
            SettingsView()
        }
    }
}
```

## Common Shell Helper

```swift
@discardableResult
func shell(_ args: String...) async throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = args
    
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe
    
    return try await withCheckedThrowingContinuation { continuation in
        process.terminationHandler = { process in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if process.terminationStatus == 0 {
                continuation.resume(returning: data)
            } else {
                continuation.resume(throwing: ShellError.exitCode(
                    process.terminationStatus, 
                    String(data: data, encoding: .utf8)
                ))
            }
        }
        
        do {
            try process.run()
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
```

## Testing Strategy

- **Unit Tests:** ViewModels, Services, AppcastParser (mock network)
- **Integration Tests:** Actual simctl/adb calls (requires simulators/emulators)
- Use Swift Testing framework (`@Test`, `#expect`)

```swift
@Test func parseAppcastReturnsExpectedItems() throws {
    let xml = """
    <?xml version="1.0"?>
    <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
      <channel>
        <item>
          <title>Version 1.0.0</title>
          <sparkle:version>100</sparkle:version>
          <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
          <pubDate>Wed, 01 Jan 2025 00:00:00 +0000</pubDate>
          <enclosure url="https://example.com/app.zip" length="1000" />
        </item>
      </channel>
    </rss>
    """
    
    let items = try AppcastParser().parse(data: Data(xml.utf8))
    
    #expect(items.count == 1)
    #expect(items.first?.shortVersion == "1.0.0")
    #expect(items.first?.bundleVersion == "100")
}

@Test func fetchIndexDecodesCorrectly() async throws {
    let mockSession = MockURLSession(responseData: sampleIndexJSON)
    let service = AppIndexService(indexURL: testURL, session: mockSession)
    
    let index = try await service.fetchIndex()
    
    #expect(index.apps.count == 2)
    #expect(index.apps.first?.platform == .ios)
}
```

## Build & Run

```bash
# Build
xcodebuild -scheme Sparkly -configuration Debug build

# Run tests
xcodebuild -scheme Sparkly -configuration Debug test

# Archive for distribution
xcodebuild -scheme Sparkly -configuration Release archive
```

## Dependencies

Prefer minimal dependencies. If needed:

- **Sparkle** — For self-updates of Sparkly itself (dogfooding!)
- **KeychainAccess** — If storing credentials for authenticated index URLs

Add via Swift Package Manager in Xcode.

## Environment Requirements

- macOS 14.0+ (Sonoma)
- Xcode 16+ with iOS Simulators
- Android SDK with `platform-tools` and `emulator` (optional, for Android support)
  - Default path: `~/Library/Android/sdk`
  - Environment variable: `ANDROID_HOME`

## UI/UX Guidelines

- **Native Feel:** Use standard macOS patterns (sidebars, toolbars, settings)
- **Source List Sidebar:** Devices on top, apps from index below (grouped by platform)
- **Main Content:** Build list showing version, build number, date, release notes, download status
- **Toolbar Actions:** Refresh, filter by platform, search
- **Progress:** Show download progress inline; support queue of downloads
- **Release Notes:** Show HTML release notes in a popover or detail pane
- **Drag & Drop:** Support dropping .app/.apk files for manual install
- **Keyboard Shortcuts:** ⌘R refresh, ⌘, settings, Enter to install selected

## Configuration

Settings should allow:

- **Index URL:** The URL to the Sparkly index JSON file
- **Cache Location:** Where to store downloaded builds (default: `~/Library/Caches/Sparkly`)
- **Cache Size Limit:** Maximum disk space for cached builds
- **Android SDK Path:** Override path to Android SDK
- **Auto-refresh Interval:** How often to poll for updates (or disable)

## Future Considerations

- Multiple index sources (personal + team indexes)
- EdDSA signature verification for downloads
- Notification on new builds (polling or background refresh)
- Menu bar mode for quick access
- Deep link support (`sparkley://install?app=com.example.app&version=1.2.3`)
- Delta updates (if appcast includes delta enclosures)
