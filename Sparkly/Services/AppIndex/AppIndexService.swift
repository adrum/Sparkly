import Foundation

actor AppIndexService {
    private let session: URLSession
    private var indexURLs: [URL] = []
    private var cachedIndex: AppIndex?
    private let parser = AppcastParser()

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Configure with a single index URL (legacy support)
    func configure(indexURL: URL) {
        self.indexURLs = [indexURL]
        self.cachedIndex = nil
    }

    /// Configure with multiple index URLs
    func configure(indexURLs: [URL]) {
        self.indexURLs = indexURLs
        self.cachedIndex = nil
    }

    var configuredIndexURL: URL? {
        indexURLs.first
    }

    var configuredIndexURLs: [URL] {
        indexURLs
    }

    /// Fetch a single index (uses first configured URL for legacy compatibility)
    func fetchIndex() async throws -> AppIndex {
        guard let indexURL = indexURLs.first else {
            throw SparklyError.noIndexConfigured
        }

        return try await fetchIndex(from: indexURL)
    }

    /// Fetch and merge all configured indexes
    func fetchAllIndexes() async throws -> AppIndex {
        guard !indexURLs.isEmpty else {
            throw SparklyError.noIndexConfigured
        }

        // Fetch all indexes in parallel
        let indexes = await withTaskGroup(of: AppIndex?.self) { group in
            for url in indexURLs {
                group.addTask {
                    try? await self.fetchIndex(from: url)
                }
            }

            var results: [AppIndex] = []
            for await index in group {
                if let index {
                    results.append(index)
                }
            }
            return results
        }

        // Merge all indexes into one
        let mergedApps = indexes.flatMap { $0.apps }
        let mergedIndex = AppIndex(
            version: indexes.first?.version ?? 1,
            title: indexes.count == 1 ? indexes.first?.title : "Combined Index",
            apps: mergedApps
        )

        cachedIndex = mergedIndex
        return mergedIndex
    }

    private func fetchIndex(from url: URL) async throws -> AppIndex {
        do {
            let data = try await fetchData(from: url)
            let decoder = JSONDecoder()
            return try decoder.decode(AppIndex.self, from: data)
        } catch let error as DecodingError {
            throw SparklyError.indexDecodingFailed(underlying: error)
        } catch let error as SparklyError {
            throw error
        } catch {
            throw SparklyError.indexFetchFailed(underlying: error)
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
        } catch let error as SparklyError {
            throw error
        } catch {
            throw SparklyError.appcastFetchFailed(app.appcastURL, underlying: error)
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
