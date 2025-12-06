# Sparkley

A native macOS app for distributing and installing development builds to iOS Simulators and Android Emulators. Think "Sparkle for simulators" — a polished update client for your team's internal builds.

## Why Sparkley?

Building mobile apps means constantly testing new builds across different devices. Sparkley streamlines this workflow for development teams by:

- **Centralizing build distribution** — Host your builds anywhere (S3, internal servers, GitHub releases) and let Sparkley handle discovery and installation
- **Supporting both platforms** — iOS Simulators and Android Emulators in one unified interface
- **Leveraging existing infrastructure** — Uses the battle-tested [Sparkle appcast format](https://sparkle-project.org/documentation/publishing/) that many teams already use
- **Zero configuration for developers** — Once your team sets up a feed, developers just add the URL and go

## Quick Start

### For Developers

1. Download Sparkley from [Releases](https://github.com/adrum/Sparkley/releases)
2. Open **Settings** (⌘,) and add your team's index URL
3. Browse available builds in the sidebar and install with one click

### For Teams Setting Up Distribution

Setting up Sparkley for your team involves two steps:

1. Create appcast feeds for each app (standard Sparkle format)
2. Create a Sparkley index file that points to your appcasts

## Creating a Sparkley Index

The Sparkley index is a simple JSON file that lists your apps and their appcast URLs:

```json
{
  "version": 1,
  "title": "Acme Corp Development Builds",
  "apps": [
    {
      "id": "com.acme.app",
      "name": "Acme App",
      "icon": "https://builds.acme.com/icons/acme-app.png",
      "platform": "ios",
      "appcastURL": "https://builds.acme.com/acme-app/appcast.xml"
    },
    {
      "id": "com.acme.app",
      "name": "Acme App",
      "icon": "https://builds.acme.com/icons/acme-app.png",
      "platform": "android",
      "appcastURL": "https://builds.acme.com/acme-app-android/appcast.xml"
    },
    {
      "id": "com.acme.dashboard",
      "name": "Acme Dashboard",
      "icon": "https://builds.acme.com/icons/dashboard.png",
      "platform": "ios",
      "appcastURL": "https://builds.acme.com/dashboard/appcast.xml"
    }
  ]
}
```

### Index Fields

| Field     | Required | Description                          |
| --------- | -------- | ------------------------------------ |
| `version` | Yes      | Index format version (currently `1`) |
| `title`   | No       | Display name for this index          |
| `apps`    | Yes      | Array of app entries                 |

### App Entry Fields

| Field        | Required | Description                                       |
| ------------ | -------- | ------------------------------------------------- |
| `id`         | Yes      | Bundle identifier (iOS) or package name (Android) |
| `name`       | Yes      | Display name                                      |
| `icon`       | No       | URL to app icon (PNG, 128x128 recommended)        |
| `platform`   | Yes      | Either `"ios"` or `"android"`                     |
| `appcastURL` | Yes      | URL to the Sparkle appcast XML                    |

## Creating Appcasts

Sparkley uses the standard [Sparkle appcast format](https://sparkle-project.org/documentation/publishing/). Here's an example:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Acme App Simulator Builds</title>
    <link>https://builds.acme.com/acme-app</link>
    <description>Development builds for Acme App</description>
    <language>en</language>

    <item>
      <title>Version 2.1.0 (142)</title>
      <pubDate>Mon, 15 Jan 2025 10:30:00 +0000</pubDate>
      <sparkle:version>142</sparkle:version>
      <sparkle:shortVersionString>2.1.0</sparkle:shortVersionString>
      <description><![CDATA[
        <h2>What's New</h2>
        <ul>
          <li>Added dark mode support</li>
          <li>Fixed crash on launch</li>
          <li>Performance improvements</li>
        </ul>
      ]]></description>
      <enclosure
        url="https://builds.acme.com/acme-app/AcmeApp-2.1.0.app.zip"
        length="45000000"
        type="application/octet-stream" />
    </item>

    <item>
      <title>Version 2.0.0 (138)</title>
      <pubDate>Fri, 10 Jan 2025 14:00:00 +0000</pubDate>
      <sparkle:version>138</sparkle:version>
      <sparkle:shortVersionString>2.0.0</sparkle:shortVersionString>
      <description><![CDATA[<p>Major redesign with new navigation</p>]]></description>
      <enclosure
        url="https://builds.acme.com/acme-app/AcmeApp-2.0.0.app.zip"
        length="44500000"
        type="application/octet-stream" />
    </item>
  </channel>
</rss>
```

### Build Artifacts

**iOS Simulator builds** should be:

- A zipped `.app` bundle built for the simulator architecture
- Build with `xcodebuild -sdk iphonesimulator` or select "Any iOS Simulator Device" in Xcode

**Android Emulator builds** should be:

- An `.apk` file (not AAB)
- Can be a debug or release APK

For more details on the appcast format, see the [Sparkle documentation](https://sparkle-project.org/documentation/publishing/).

## Hosting Options

Your index and appcast files can be hosted anywhere accessible via HTTP/HTTPS.

### Example: S3 Setup

```
your-builds-repo/
├── sparkley-index.json      # Your Sparkley index
├── ios-app/
│   ├── appcast.xml          # iOS appcast
│   └── builds/
│       ├── App-1.0.0.app.zip
│       └── App-1.1.0.app.zip
└── android-app/
    ├── appcast.xml          # Android appcast
    └── builds/
        ├── App-1.0.0.apk
        └── App-1.1.0.apk
```

Enable GitHub Pages on the repo and use URLs like:

```
https://your-org.github.io/your-builds-repo/sparkley-index.json
```

## Multiple Index Sources

Sparkley supports multiple index sources, useful for:

- **Personal builds** alongside team builds
- **Multiple teams** within an organization
- **Project-specific** feeds

Add multiple sources in **Settings → Index Sources**. Apps from all enabled sources are combined in the sidebar.

## Features

- **Unified device management** — View and control iOS Simulators and Android Emulators
- **One-click installation** — Download and install builds to any running device
- **Build caching** — Previously downloaded builds are cached locally
- **Release notes** — View what's new in each build
- **Platform filtering** — Focus on iOS or Android builds
- **Search** — Quickly find apps across all sources
- **Launch installed apps** — See and launch apps already on your devices

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode (for iOS Simulator support)
- Android SDK with `platform-tools` and `emulator` (for Android support)

## Building from Source

```bash
git clone https://github.com/adrum/Sparkley.git
cd Sparkley
open Sparkley.xcodeproj
```

Build and run with ⌘R.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Sparkle](https://sparkle-project.org/) for the appcast format that makes this possible
- Built with SwiftUI for macOS
