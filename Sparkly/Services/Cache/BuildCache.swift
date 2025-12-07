import Foundation

actor BuildCache {
    private let cacheDirectory: URL
    private let policy: CachePolicy
    private let fileManager = FileManager.default

    init(
        cacheDirectory: URL? = nil,
        policy: CachePolicy = .default
    ) {
        if let cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            self.cacheDirectory = cachesDir.appendingPathComponent("Sparkly", isDirectory: true)
        }
        self.policy = policy

        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
    }

    func cachedPath(for item: AppcastItem, app: AppEntry) -> URL? {
        let path = buildPath(for: item, app: app)
        guard fileManager.fileExists(atPath: path.path) else {
            return nil
        }

        try? fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: path.path
        )

        return path
    }

    func store(_ tempURL: URL, for item: AppcastItem, app: AppEntry) async throws -> URL {
        try await evictIfNeeded()

        let destination = buildPath(for: item, app: app)
        let parentDirectory = destination.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(
                at: parentDirectory,
                withIntermediateDirectories: true
            )

            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }

            try fileManager.copyItem(at: tempURL, to: destination)

            return destination
        } catch {
            throw SparklyError.cacheStoreFailed(underlying: error)
        }
    }

    func remove(for item: AppcastItem, app: AppEntry) throws {
        let path = buildPath(for: item, app: app)
        if fileManager.fileExists(atPath: path.path) {
            try fileManager.removeItem(at: path)
        }
    }

    func clearCache() async throws {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: nil
            )
            for item in contents {
                try fileManager.removeItem(at: item)
            }
        } catch {
            throw SparklyError.cacheEvictionFailed(underlying: error)
        }
    }

    func currentCacheSize() throws -> Int64 {
        try calculateDirectorySize(cacheDirectory)
    }

    func evictIfNeeded() async throws {
        let currentSize = try currentCacheSize()

        guard currentSize > policy.evictionTriggerSize else {
            return
        }

        try await evictToTargetSize(policy.targetSizeAfterEviction)
    }

    private func evictToTargetSize(_ targetSize: Int64) async throws {
        let items = try getCachedItemsSortedByAccessDate()

        var currentSize = try currentCacheSize()
        var index = 0

        while currentSize > targetSize && index < items.count {
            let item = items[index]
            let itemSize = try calculateFileSize(item.url)

            do {
                try fileManager.removeItem(at: item.url)
                currentSize -= itemSize
            } catch {
                // Continue evicting other items
            }

            index += 1
        }
    }

    private func getCachedItemsSortedByAccessDate() throws -> [(url: URL, accessDate: Date)] {
        var items: [(url: URL, accessDate: Date)] = []

        let enumerator = fileManager.enumerator(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        while let url = enumerator?.nextObject() as? URL {
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey])

            guard let isDirectory = resourceValues.isDirectory, !isDirectory else {
                continue
            }

            let accessDate = resourceValues.contentModificationDate ?? Date.distantPast
            items.append((url: url, accessDate: accessDate))
        }

        return items.sorted { $0.accessDate < $1.accessDate }
    }

    private func calculateDirectorySize(_ url: URL) throws -> Int64 {
        var totalSize: Int64 = 0

        let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if let isDirectory = resourceValues.isDirectory, !isDirectory {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }

        return totalSize
    }

    private func calculateFileSize(_ url: URL) throws -> Int64 {
        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(resourceValues.fileSize ?? 0)
    }

    private func buildPath(for item: AppcastItem, app: AppEntry) -> URL {
        cacheDirectory
            .appendingPathComponent(app.id, isDirectory: true)
            .appendingPathComponent("\(item.shortVersion)-\(item.bundleVersion)", isDirectory: true)
    }

    var cacheLocation: URL {
        cacheDirectory
    }
}
