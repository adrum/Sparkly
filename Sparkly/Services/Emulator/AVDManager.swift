import Foundation

actor AVDManager {
    private var emulatorPath: String?
    private var avdmanagerPath: String?

    init() {
        let (emulator, avdmanager) = findPaths()
        self.emulatorPath = emulator
        self.avdmanagerPath = avdmanager
    }

    private func findAndroidHome() -> String {
        // Check common Android SDK locations
        let possiblePaths = [
            "~/.android".expandingTildeInPath,
            "~/Library/Android/sdk".expandingTildeInPath,
            "/opt/android-sdk"
        ]

        for path in possiblePaths {
            let emulatorPath = "\(path)/emulator/emulator"
            let adbPath = "\(path)/platform-tools/adb"
            if FileManager.default.fileExists(atPath: emulatorPath) ||
               FileManager.default.fileExists(atPath: adbPath) {
                return path
            }
        }

        // Default fallback
        return "~/Library/Android/sdk".expandingTildeInPath
    }

    private func findPaths() -> (emulator: String?, avdmanager: String?) {
        let androidHome = ProcessInfo.processInfo.environment["ANDROID_HOME"]
            ?? ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"]
            ?? findAndroidHome()

        let emulatorPath = "\(androidHome)/emulator/emulator"
        let avdmanagerPath = "\(androidHome)/cmdline-tools/latest/bin/avdmanager"
        let legacyAvdmanagerPath = "\(androidHome)/tools/bin/avdmanager"

        let emulator = FileManager.default.fileExists(atPath: emulatorPath) ? emulatorPath : nil

        var avdmanager: String?
        if FileManager.default.fileExists(atPath: avdmanagerPath) {
            avdmanager = avdmanagerPath
        } else if FileManager.default.fileExists(atPath: legacyAvdmanagerPath) {
            avdmanager = legacyAvdmanagerPath
        }

        return (emulator, avdmanager)
    }

    func isAvailable() -> Bool {
        emulatorPath != nil
    }

    func getEmulatorPath() throws -> String {
        guard let path = emulatorPath else {
            throw SparklyError.emulatorNotFound("Emulator not found in Android SDK")
        }
        return path
    }

    func listAVDs() async throws -> [AVDInfo] {
        let emulator = try getEmulatorPath()
        let data = try await shell(emulator, "-list-avds")

        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        let avdNames = output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return avdNames.map { AVDInfo(name: $0) }
    }

    func launchAVD(name: String, coldBoot: Bool = false) async throws {
        let emulator = try getEmulatorPath()

        var args = ["-avd", name]
        if coldBoot {
            args.append("-no-snapshot-load")
        }

        // Launch emulator in detached mode
        try await launchDetached(emulator, arguments: args)
    }

    func killEmulator(serial: String) async throws {
        // Use adb to kill the emulator
        let androidHome = ProcessInfo.processInfo.environment["ANDROID_HOME"]
            ?? ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"]
            ?? findAndroidHome()

        let adbPath = "\(androidHome)/platform-tools/adb"

        if FileManager.default.fileExists(atPath: adbPath) {
            try await shell(adbPath, "-s", serial, "emu", "kill")
        }
    }

    private func launchDetached(_ executable: String, arguments: [String]) async throws {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: executable)
        task.arguments = arguments

        // Redirect output to /dev/null so the emulator runs detached
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice

        try task.run()
        // Don't wait for it to finish - it will run in the background
    }
}

struct AVDInfo: Identifiable, Sendable {
    let name: String

    var id: String { name }

    var displayName: String {
        name.replacingOccurrences(of: "_", with: " ")
    }
}

private extension String {
    var expandingTildeInPath: String {
        if hasPrefix("~") {
            return (self as NSString).expandingTildeInPath
        }
        return self
    }
}
