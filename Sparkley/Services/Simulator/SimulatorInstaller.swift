import Foundation

actor SimulatorInstaller {
    private let simctlService: SimctlService
    private let fileManager = FileManager.default

    init(simctlService: SimctlService) {
        self.simctlService = simctlService
    }

    func install(
        archivePath: URL,
        app: AppEntry,
        device: SimulatorDevice
    ) async throws {
        guard app.platform == .ios else {
            throw SparkleyError.unsupportedPlatform(app.platform)
        }

        let appPath = try await extractIfNeeded(archivePath)

        if !device.isBooted {
            try await simctlService.boot(udid: device.udid)
            try await Task.sleep(for: .seconds(2))
        }

        try await simctlService.install(udid: device.udid, appPath: appPath)
        try await simctlService.launch(udid: device.udid, bundleID: app.id)
    }

    private func extractIfNeeded(_ archivePath: URL) async throws -> URL {
        let pathExtension = archivePath.pathExtension.lowercased()

        switch pathExtension {
        case "app":
            return archivePath

        case "zip":
            return try await extractZip(archivePath)

        default:
            if fileManager.fileExists(atPath: archivePath.appendingPathComponent("Contents").path) {
                return archivePath
            }
            throw SparkleyError.extractionFailed(archivePath, underlying: nil)
        }
    }

    private func extractZip(_ zipPath: URL) async throws -> URL {
        let extractionDirectory = zipPath.deletingLastPathComponent()
            .appendingPathComponent("extracted_\(UUID().uuidString)")

        try fileManager.createDirectory(at: extractionDirectory, withIntermediateDirectories: true)

        do {
            try await shell("unzip", "-o", "-q", zipPath.path, "-d", extractionDirectory.path)
        } catch let error as ShellError {
            try? fileManager.removeItem(at: extractionDirectory)
            throw SparkleyError.extractionFailed(zipPath, underlying: error)
        }

        let appBundle = try findAppBundle(in: extractionDirectory)
        return appBundle
    }

    private func findAppBundle(in directory: URL) throws -> URL {
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        if let appBundle = contents.first(where: { $0.pathExtension == "app" }) {
            return appBundle
        }

        for item in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDirectory),
               isDirectory.boolValue {
                if let found = try? findAppBundle(in: item) {
                    return found
                }
            }
        }

        throw SparkleyError.extractionFailed(directory, underlying: nil)
    }
}
