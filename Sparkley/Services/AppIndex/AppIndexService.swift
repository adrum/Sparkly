import Foundation

actor AppIndexService {
    private let session: URLSession
    private var indexURL: URL?
    private var cachedIndex: AppIndex?
    private let parser = AppcastParser()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func configure(indexURL: URL) {
        self.indexURL = indexURL
        self.cachedIndex = nil
    }

    var configuredIndexURL: URL? {
        indexURL
    }

    func fetchIndex() async throws -> AppIndex {
        guard let indexURL else {
            throw SparkleyError.noIndexConfigured
        }

        do {
            let data = try await fetchData(from: indexURL)
            let decoder = JSONDecoder()
            let index = try decoder.decode(AppIndex.self, from: data)
            cachedIndex = index
            return index
        } catch let error as DecodingError {
            throw SparkleyError.indexDecodingFailed(underlying: error)
        } catch let error as SparkleyError {
            throw error
        } catch {
            throw SparkleyError.indexFetchFailed(underlying: error)
        }
    }

    private func fetchData(from url: URL) async throws -> Data {
        if url.isFileURL {
            return try Data(contentsOf: url)
        } else {
            let (data, _) = try await session.data(from: url)
            return data
        }
    }

    func fetchAppcast(for app: AppEntry) async throws -> [AppcastItem] {
        do {
            let data = try await fetchData(from: app.appcastURL)
            return try parser.parse(data: data)
        } catch let error as SparkleyError {
            throw error
        } catch {
            throw SparkleyError.appcastFetchFailed(app.appcastURL, underlying: error)
        }
    }

    func fetchAllAppcasts(for index: AppIndex) async throws -> [AppWithBuilds] {
        try await withThrowingTaskGroup(of: AppWithBuilds?.self) { group in
            for app in index.apps {
                group.addTask {
                    do {
                        let builds = try await self.fetchAppcast(for: app)
                        let sortedBuilds = builds.sorted { $0.pubDate > $1.pubDate }
                        return AppWithBuilds(app: app, builds: sortedBuilds)
                    } catch {
                        print("Failed to fetch appcast for \(app.name): \(error)")
                        return AppWithBuilds(app: app, builds: [])
                    }
                }
            }

            var results: [AppWithBuilds] = []
            for try await appWithBuilds in group {
                if let appWithBuilds {
                    results.append(appWithBuilds)
                }
            }
            return results.sorted { $0.app.name.localizedCaseInsensitiveCompare($1.app.name) == .orderedAscending }
        }
    }

    func getCachedIndex() -> AppIndex? {
        cachedIndex
    }
}
