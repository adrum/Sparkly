//
//  AppcastParserTests.swift
//  SparkleyTests
//
//  Created by Austin Drummond on 12/6/25.
//

import Foundation
import Testing
@testable import Sparkley

struct AppcastParserTests {

    @Test func parseValidAppcast() throws {
        let xml = """
        <?xml version="1.0" encoding="utf-8"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <title>Test App Builds</title>
            <item>
              <title>Version 1.0.0 (100)</title>
              <pubDate>Wed, 15 Jan 2025 10:30:00 +0000</pubDate>
              <sparkle:version>100</sparkle:version>
              <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
              <description><![CDATA[<h2>What's New</h2><ul><li>Initial release</li></ul>]]></description>
              <enclosure url="https://example.com/app.zip" length="50000000" type="application/octet-stream" />
            </item>
          </channel>
        </rss>
        """

        let parser = AppcastParser()
        let items = try parser.parse(data: Data(xml.utf8))

        #expect(items.count == 1)

        let item = try #require(items.first)
        #expect(item.title == "Version 1.0.0 (100)")
        #expect(item.bundleVersion == "100")
        #expect(item.shortVersion == "1.0.0")
        #expect(item.enclosureURL == URL(string: "https://example.com/app.zip"))
        #expect(item.enclosureLength == 50000000)
        #expect(item.releaseNotes?.contains("Initial release") == true)
    }

    @Test func parseMultipleItems() throws {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <item>
              <title>Version 2.0.0</title>
              <pubDate>Wed, 20 Jan 2025 12:00:00 +0000</pubDate>
              <sparkle:version>200</sparkle:version>
              <sparkle:shortVersionString>2.0.0</sparkle:shortVersionString>
              <enclosure url="https://example.com/app2.zip" length="60000000" />
            </item>
            <item>
              <title>Version 1.0.0</title>
              <pubDate>Wed, 15 Jan 2025 10:00:00 +0000</pubDate>
              <sparkle:version>100</sparkle:version>
              <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
              <enclosure url="https://example.com/app1.zip" length="50000000" />
            </item>
          </channel>
        </rss>
        """

        let parser = AppcastParser()
        let items = try parser.parse(data: Data(xml.utf8))

        #expect(items.count == 2)
        #expect(items[0].shortVersion == "2.0.0")
        #expect(items[1].shortVersion == "1.0.0")
    }

    @Test func parseWithEdSignature() throws {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <item>
              <title>Version 1.0.0</title>
              <pubDate>Wed, 15 Jan 2025 10:00:00 +0000</pubDate>
              <sparkle:version>100</sparkle:version>
              <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
              <enclosure
                url="https://example.com/app.zip"
                length="50000000"
                sparkle:edSignature="BASE64_SIGNATURE_HERE" />
            </item>
          </channel>
        </rss>
        """

        let parser = AppcastParser()
        let items = try parser.parse(data: Data(xml.utf8))

        #expect(items.first?.edSignature == "BASE64_SIGNATURE_HERE")
    }

    @Test func parseEmptyChannel() throws {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <title>Empty Feed</title>
          </channel>
        </rss>
        """

        let parser = AppcastParser()
        let items = try parser.parse(data: Data(xml.utf8))

        #expect(items.isEmpty)
    }

    @Test func parseSkipsIncompleteItems() throws {
        let xml = """
        <?xml version="1.0"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
          <channel>
            <item>
              <title>Missing Version</title>
              <pubDate>Wed, 15 Jan 2025 10:00:00 +0000</pubDate>
              <enclosure url="https://example.com/app.zip" />
            </item>
            <item>
              <title>Complete Item</title>
              <pubDate>Wed, 15 Jan 2025 10:00:00 +0000</pubDate>
              <sparkle:version>100</sparkle:version>
              <sparkle:shortVersionString>1.0.0</sparkle:shortVersionString>
              <enclosure url="https://example.com/app.zip" />
            </item>
          </channel>
        </rss>
        """

        let parser = AppcastParser()
        let items = try parser.parse(data: Data(xml.utf8))

        #expect(items.count == 1)
        #expect(items.first?.shortVersion == "1.0.0")
    }

    @Test func appcastItemId() {
        let item = AppcastItem(
            title: "Test",
            pubDate: Date(),
            bundleVersion: "100",
            shortVersion: "1.0.0",
            releaseNotes: nil,
            enclosureURL: URL(string: "https://example.com/app.zip")!,
            enclosureLength: nil,
            edSignature: nil
        )

        #expect(item.id == "100-1.0.0")
    }

    @Test func appcastItemDisplayVersion() {
        let item = AppcastItem(
            title: "Test",
            pubDate: Date(),
            bundleVersion: "456",
            shortVersion: "1.2.3",
            releaseNotes: nil,
            enclosureURL: URL(string: "https://example.com/app.zip")!,
            enclosureLength: nil,
            edSignature: nil
        )

        #expect(item.displayVersion == "1.2.3 (456)")
    }
}
