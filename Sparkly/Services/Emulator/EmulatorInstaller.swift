import Foundation

struct EmulatorInstaller {
    private let adbService: ADBService

    init(adbService: ADBService) {
        self.adbService = adbService
    }

    func install(archivePath: URL, app: AppEntry, device: EmulatorDevice) async throws {
        // For Android, the archive is typically a .apk file or a .zip containing an .apk
        let apkPath: URL

        if archivePath.pathExtension.lowercased() == "apk" {
            apkPath = archivePath
        } else if archivePath.pathExtension.lowercased() == "zip" {
            apkPath = try await extractAPK(from: archivePath)
        } else {
            throw SparklyError.extractionFailed(archivePath, underlying: nil)
        }

        // Install the APK
        try await adbService.install(serial: device.serial, apkPath: apkPath)

        // Launch the app
        try await adbService.launch(serial: device.serial, packageName: app.id)
    }

    private func extractAPK(from archive: URL) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Use ditto to extract the zip
        try await shell("ditto", "-xk", archive.path, tempDir.path)

        // Find the .apk file
        let contents = try FileManager.default.contentsOfDirectory(
            at: tempDir,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        // Look for .apk file recursively
        if let apk = try findAPK(in: tempDir) {
            return apk
        }

        throw SparklyError.extractionFailed(archive, underlying: nil)
    }

    private func findAPK(in directory: URL) throws -> URL? {
        let contents = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for item in contents {
            let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])

            if resourceValues.isDirectory == true {
                if let apk = try findAPK(in: item) {
                    return apk
                }
            } else if item.pathExtension.lowercased() == "apk" {
                return item
            }
        }

        return nil
    }
}
