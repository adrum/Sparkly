import Foundation
import Observation

@Observable
final class SettingsViewModel {
    var indexSources: [IndexSource] {
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
        static let indexURL = "indexURL"  // Legacy key for migration
        static let indexSources = "indexSources"
        static let maxCacheSizeGB = "maxCacheSizeGB"
        static let autoRefreshEnabled = "autoRefreshEnabled"
        static let autoRefreshInterval = "autoRefreshIntervalMinutes"
    }

    init() {
        let storedCacheSize = UserDefaults.standard.double(forKey: Keys.maxCacheSizeGB)
        let storedRefreshInterval = UserDefaults.standard.integer(forKey: Keys.autoRefreshInterval)

        // Load index sources
        if let data = UserDefaults.standard.data(forKey: Keys.indexSources),
           let sources = try? JSONDecoder().decode([IndexSource].self, from: data) {
            self.indexSources = sources
        } else if let legacyURL = UserDefaults.standard.string(forKey: Keys.indexURL), !legacyURL.isEmpty {
            // Migrate from single URL to sources array
            self.indexSources = [IndexSource(name: "Default", urlString: legacyURL)]
        } else {
            self.indexSources = []
        }

        self.maxCacheSizeGB = storedCacheSize == 0 ? 10.0 : storedCacheSize
        self.autoRefreshEnabled = UserDefaults.standard.bool(forKey: Keys.autoRefreshEnabled)
        self.autoRefreshIntervalMinutes = storedRefreshInterval == 0 ? 30 : storedRefreshInterval
    }

    // MARK: - Legacy Compatibility

    /// Returns the first enabled index URL for backward compatibility
    var indexURLString: String {
        get { indexSources.first(where: { $0.isEnabled })?.urlString ?? "" }
        set {
            if indexSources.isEmpty {
                indexSources = [IndexSource(name: "Default", urlString: newValue)]
            } else if let index = indexSources.firstIndex(where: { $0.isEnabled }) {
                indexSources[index].urlString = newValue
            }
        }
    }

    var indexURL: URL? {
        indexSources.first(where: { $0.isEnabled && $0.isValid })?.url
    }

    var enabledIndexURLs: [URL] {
        indexSources.filter { $0.isEnabled && $0.isValid }.compactMap { $0.url }
    }

    var isIndexURLValid: Bool {
        !enabledIndexURLs.isEmpty
    }

    // MARK: - Index Source Management

    func addSource(name: String, urlString: String) {
        let source = IndexSource(name: name, urlString: urlString)
        indexSources.append(source)
    }

    func removeSource(_ source: IndexSource) {
        indexSources.removeAll { $0.id == source.id }
    }

    func toggleSource(_ source: IndexSource) {
        if let index = indexSources.firstIndex(where: { $0.id == source.id }) {
            indexSources[index].isEnabled.toggle()
        }
    }

    // MARK: - Cache Settings

    var maxCacheSizeBytes: Int64 {
        Int64(maxCacheSizeGB * 1_000_000_000)
    }

    var autoRefreshInterval: TimeInterval? {
        guard autoRefreshEnabled else { return nil }
        return TimeInterval(autoRefreshIntervalMinutes * 60)
    }

    func save() {
        if let data = try? JSONEncoder().encode(indexSources) {
            defaults.set(data, forKey: Keys.indexSources)
        }
        defaults.set(maxCacheSizeGB, forKey: Keys.maxCacheSizeGB)
        defaults.set(autoRefreshEnabled, forKey: Keys.autoRefreshEnabled)
        defaults.set(autoRefreshIntervalMinutes, forKey: Keys.autoRefreshInterval)
    }

    func reset() {
        indexSources = []
        maxCacheSizeGB = 10.0
        autoRefreshEnabled = false
        autoRefreshIntervalMinutes = 30
    }
}
