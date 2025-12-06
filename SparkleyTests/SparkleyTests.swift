//
//  SparkleyTests.swift
//  SparkleyTests
//
//  Created by Austin Drummond on 12/6/25.
//

import Foundation
import Testing
@testable import Sparkley

struct SparkleyTests {

    @Test func platformDisplayName() {
        #expect(Platform.ios.displayName == "iOS")
        #expect(Platform.android.displayName == "Android")
    }

    @Test func platformSystemImage() {
        #expect(Platform.ios.systemImage == "iphone")
        #expect(Platform.android.systemImage == "android")
    }

    @Test func simulatorDeviceState() {
        #expect(SimulatorDevice.DeviceState.booted.rawValue == "Booted")
        #expect(SimulatorDevice.DeviceState.shutdown.rawValue == "Shutdown")
    }

    @Test func simulatorDeviceIsBooted() {
        let bootedDevice = SimulatorDevice(
            udid: "123",
            name: "iPhone 15",
            deviceTypeIdentifier: "test",
            runtime: "iOS-17-0",
            state: .booted,
            isAvailable: true
        )

        let shutdownDevice = SimulatorDevice(
            udid: "456",
            name: "iPhone 15",
            deviceTypeIdentifier: "test",
            runtime: "iOS-17-0",
            state: .shutdown,
            isAvailable: true
        )

        #expect(bootedDevice.isBooted == true)
        #expect(shutdownDevice.isBooted == false)
    }

    @Test func appWithBuildsSortedBuilds() {
        let app = AppEntry(
            id: "com.example.app",
            name: "Test",
            icon: nil,
            platform: .ios,
            appcastURL: URL(string: "https://example.com/appcast.xml")!
        )

        let olderBuild = AppcastItem(
            title: "Older",
            pubDate: Date(timeIntervalSince1970: 1000),
            bundleVersion: "100",
            shortVersion: "1.0.0",
            releaseNotes: nil,
            enclosureURL: URL(string: "https://example.com/app1.zip")!,
            enclosureLength: nil,
            edSignature: nil
        )

        let newerBuild = AppcastItem(
            title: "Newer",
            pubDate: Date(timeIntervalSince1970: 2000),
            bundleVersion: "200",
            shortVersion: "2.0.0",
            releaseNotes: nil,
            enclosureURL: URL(string: "https://example.com/app2.zip")!,
            enclosureLength: nil,
            edSignature: nil
        )

        let appWithBuilds = AppWithBuilds(app: app, builds: [olderBuild, newerBuild])

        #expect(appWithBuilds.sortedBuilds.first?.shortVersion == "2.0.0")
        #expect(appWithBuilds.latestBuild?.shortVersion == "1.0.0") // first in original array
    }

    @Test func cachePolicyDefaults() {
        let policy = CachePolicy.default

        #expect(policy.maxCacheSize == 10_000_000_000)
        #expect(policy.evictionThreshold == 0.9)
    }

    @Test func cachePolicyEvictionTriggerSize() {
        let policy = CachePolicy(maxCacheSize: 10_000_000_000, evictionThreshold: 0.9)

        #expect(policy.evictionTriggerSize == 9_000_000_000)
    }
}
