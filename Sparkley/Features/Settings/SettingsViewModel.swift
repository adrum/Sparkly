import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var indexURLString: String {
        didSet {
            save()
        }
    }

    var maxCacheSizeGB: Double {
        didSet {
            save()
        }
    }

    var autoRefreshEnabled: Bool {
        didSet {
            save()
        }
    }

    var autoRefreshIntervalMinutes: Int {
        didSet {
            save()
        }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let indexURL = "indexURL"
        static let maxCacheSizeGB = "maxCacheSizeGB"
        static let autoRefreshEnabled = "autoRefreshEnabled"
        static let autoRefreshInterval = "autoRefreshIntervalMinutes"
    }

    init() {
        let storedCacheSize = UserDefaults.standard.double(forKey: Keys.maxCacheSizeGB)
        let storedRefreshInterval = UserDefaults.standard.integer(forKey: Keys.autoRefreshInterval)

        self.indexURLString = UserDefaults.standard.string(forKey: Keys.indexURL) ?? ""
        self.maxCacheSizeGB = storedCacheSize == 0 ? 10.0 : storedCacheSize
        self.autoRefreshEnabled = UserDefaults.standard.bool(forKey: Keys.autoRefreshEnabled)
        self.autoRefreshIntervalMinutes = storedRefreshInterval == 0 ? 30 : storedRefreshInterval
    }

    var indexURL: URL? {
        guard !indexURLString.isEmpty else { return nil }
        return URL(string: indexURLString)
    }

    var isIndexURLValid: Bool {
        guard let url = indexURL else { return false }
        return url.scheme == "http" || url.scheme == "https" || url.scheme == "file"
    }

    var maxCacheSizeBytes: Int64 {
        Int64(maxCacheSizeGB * 1_000_000_000)
    }

    var autoRefreshInterval: TimeInterval? {
        guard autoRefreshEnabled else { return nil }
        return TimeInterval(autoRefreshIntervalMinutes * 60)
    }

    func save() {
        defaults.set(indexURLString, forKey: Keys.indexURL)
        defaults.set(maxCacheSizeGB, forKey: Keys.maxCacheSizeGB)
        defaults.set(autoRefreshEnabled, forKey: Keys.autoRefreshEnabled)
        defaults.set(autoRefreshIntervalMinutes, forKey: Keys.autoRefreshInterval)
    }

    func reset() {
        indexURLString = ""
        maxCacheSizeGB = 10.0
        autoRefreshEnabled = false
        autoRefreshIntervalMinutes = 30
    }
}
