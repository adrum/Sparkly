//
//  AppIndexTests.swift
//  SparklyTests
//
//  Created by Austin Drummond on 12/6/25.
//

import Foundation
import Testing
@testable import Sparkly

struct AppIndexTests {

    @Test func decodeValidIndex() throws {
        let json = """
        {
          "version": 1,
          "title": "Test Builds",
          "apps": [
            {
              "id": "com.example.app",
              "name": "Example App",
              "icon": "https://example.com/icon.png",
              "platform": "ios",
              "appcastURL": "https://example.com/appcast.xml"
            }
          ]
        }
        """

        let data = Data(json.utf8)
        let index = try JSONDecoder().decode(AppIndex.self, from: data)

        #expect(index.version == 1)
        #expect(index.title == "Test Builds")
        #expect(index.apps.count == 1)
        #expect(index.apps.first?.id == "com.example.app")
        #expect(index.apps.first?.name == "Example App")
        #expect(index.apps.first?.platform == .ios)
    }

    @Test func decodeIndexWithNullTitle() throws {
        let json = """
        {
          "version": 1,
          "title": null,
          "apps": []
        }
        """

        let data = Data(json.utf8)
        let index = try JSONDecoder().decode(AppIndex.self, from: data)

        #expect(index.title == nil)
        #expect(index.apps.isEmpty)
    }

    @Test func decodeIndexWithNullIcon() throws {
        let json = """
        {
          "version": 1,
          "title": "Test",
          "apps": [
            {
              "id": "com.example.app",
              "name": "App",
              "icon": null,
              "platform": "android",
              "appcastURL": "https://example.com/appcast.xml"
            }
          ]
        }
        """

        let data = Data(json.utf8)
        let index = try JSONDecoder().decode(AppIndex.self, from: data)

        #expect(index.apps.first?.icon == nil)
        #expect(index.apps.first?.platform == .android)
    }

    @Test func appEntryIdentifiable() {
        let app = AppEntry(
            id: "com.example.app",
            name: "Test App",
            icon: nil,
            platform: .ios,
            appcastURL: URL(string: "https://example.com/appcast.xml")!
        )

        #expect(app.id == "com.example.app")
    }

    @Test func appEntryHashable() {
        let app1 = AppEntry(
            id: "com.example.app",
            name: "Test App",
            icon: nil,
            platform: .ios,
            appcastURL: URL(string: "https://example.com/appcast.xml")!
        )

        let app2 = AppEntry(
            id: "com.example.app",
            name: "Test App",
            icon: nil,
            platform: .ios,
            appcastURL: URL(string: "https://example.com/appcast.xml")!
        )

        #expect(app1 == app2)
        #expect(app1.hashValue == app2.hashValue)
    }
}
