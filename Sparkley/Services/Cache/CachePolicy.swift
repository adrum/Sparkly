import Foundation

struct CachePolicy: Sendable {
    let maxCacheSize: Int64
    let evictionThreshold: Double

    init(
        maxCacheSize: Int64 = 10_000_000_000,
        evictionThreshold: Double = 0.9
    ) {
        self.maxCacheSize = maxCacheSize
        self.evictionThreshold = evictionThreshold
    }

    var evictionTriggerSize: Int64 {
        Int64(Double(maxCacheSize) * evictionThreshold)
    }

    var targetSizeAfterEviction: Int64 {
        Int64(Double(maxCacheSize) * 0.7)
    }

    static let `default` = CachePolicy()

    static let small = CachePolicy(maxCacheSize: 1_000_000_000)

    static let large = CachePolicy(maxCacheSize: 50_000_000_000)
}
