import Foundation

final class AppcastParser: NSObject, XMLParserDelegate, @unchecked Sendable {
    private var items: [AppcastItem] = []
    private var currentElement: String = ""
    private var currentItem: PartialAppcastItem?
    private var currentText: String = ""
    private var parserError: Error?

    private struct PartialAppcastItem {
        var title: String?
        var pubDate: Date?
        var bundleVersion: String?
        var shortVersion: String?
        var releaseNotes: String?
        var enclosureURL: URL?
        var enclosureLength: Int64?
        var edSignature: String?

        func toAppcastItem() -> AppcastItem? {
            guard let title,
                  let pubDate,
                  let bundleVersion,
                  let shortVersion,
                  let enclosureURL else {
                return nil
            }

            return AppcastItem(
                title: title,
                pubDate: pubDate,
                bundleVersion: bundleVersion,
                shortVersion: shortVersion,
                releaseNotes: releaseNotes,
                enclosureURL: enclosureURL,
                enclosureLength: enclosureLength,
                edSignature: edSignature
            )
        }
    }

    func parse(data: Data) throws -> [AppcastItem] {
        items = []
        parserError = nil

        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false

        guard parser.parse() else {
            throw SparkleyError.appcastParsingFailed(parser.parserError ?? parserError)
        }

        if let error = parserError {
            throw SparkleyError.appcastParsingFailed(error)
        }

        return items
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
        currentText = ""

        switch elementName {
        case "item":
            currentItem = PartialAppcastItem()

        case "enclosure":
            if var item = currentItem {
                if let urlString = attributeDict["url"],
                   let url = URL(string: urlString) {
                    item.enclosureURL = url
                }
                if let lengthString = attributeDict["length"] ?? attributeDict["sparkle:length"] {
                    item.enclosureLength = Int64(lengthString)
                }
                if let signature = attributeDict["sparkle:edSignature"] {
                    item.edSignature = signature
                }
                currentItem = item
            }

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "item":
            if let item = currentItem?.toAppcastItem() {
                items.append(item)
            }
            currentItem = nil

        case "title":
            if currentItem != nil && !text.isEmpty {
                currentItem?.title = text
            }

        case "pubDate":
            if currentItem != nil {
                currentItem?.pubDate = parseRFC2822Date(text)
            }

        case "sparkle:version":
            if currentItem != nil && !text.isEmpty {
                currentItem?.bundleVersion = text
            }

        case "sparkle:shortVersionString":
            if currentItem != nil && !text.isEmpty {
                currentItem?.shortVersion = text
            }

        case "description":
            if currentItem != nil && !text.isEmpty {
                currentItem?.releaseNotes = text
            }

        default:
            break
        }

        currentElement = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let string = String(data: CDATABlock, encoding: .utf8) {
            currentText += string
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        parserError = parseError
    }

    // MARK: - Date Parsing

    private func parseRFC2822Date(_ string: String) -> Date? {
        let formatters = Self.dateFormatters
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }

    private static let dateFormatters: [DateFormatter] = {
        let formats = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "dd MMM yyyy HH:mm:ss Z",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        ]

        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            return formatter
        }
    }()
}
