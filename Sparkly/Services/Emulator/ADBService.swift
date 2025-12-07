import Foundation

actor ADBService {
    private var adbPath: String?

    init() {
        self.adbPath = findADBPath()
    }

    private func findADBPath() -> String? {
        // Check common locations for adb
        let possiblePaths = [
            ProcessInfo.processInfo.environment["ANDROID_HOME"].map { "\($0)/platform-tools/adb" },
            ProcessInfo.processInfo.environment["ANDROID_SDK_ROOT"].map { "\($0)/platform-tools/adb" },
            "~/.android/platform-tools/adb".expandingTildeInPath,
            "~/Library/Android/sdk/platform-tools/adb".expandingTildeInPath,
            "/usr/local/bin/adb",
            "/opt/homebrew/bin/adb"
        ].compactMap { $0 }

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return nil
    }

    func isAvailable() -> Bool {
        adbPath != nil
    }

    func getADBPath() throws -> String {
        guard let path = adbPath else {
            throw SparklyError.adbNotFound
        }
        return path
    }

    func listDevices() async throws -> [EmulatorDevice] {
        let adb = try getADBPath()
        let data = try await shell(adb, "devices", "-l")

        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return parseDeviceList(output)
    }

    private func parseDeviceList(_ output: String) -> [EmulatorDevice] {
        var devices: [EmulatorDevice] = []

        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            // Skip header and empty lines
            if line.hasPrefix("List of devices") || line.trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }

            // Parse device line: "emulator-5554 device product:sdk_gphone64_arm64 model:sdk_gphone64_arm64 device:emu64a transport_id:1"
            // or: "RFXXXXXXXX device usb:1234 product:... model:... device:... transport_id:2"
            let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }

            guard components.count >= 2 else { continue }

            let serial = components[0]
            let stateStr = components[1]
            let state = EmulatorDevice.DeviceState(rawValue: stateStr) ?? .unknown

            // Parse additional properties
            var model = ""
            var avdName: String?

            for component in components.dropFirst(2) {
                if component.hasPrefix("model:") {
                    model = String(component.dropFirst(6))
                }
            }

            // Check if it's an emulator
            let isEmulator = serial.hasPrefix("emulator-")

            // For emulators, try to get the AVD name
            if isEmulator, let port = Int(serial.replacingOccurrences(of: "emulator-", with: "")) {
                avdName = getAVDNameForPort(port)
            }

            let device = EmulatorDevice(
                serial: serial,
                name: model,
                avdName: avdName,
                state: state,
                isEmulator: isEmulator
            )
            devices.append(device)
        }

        return devices
    }

    private func getAVDNameForPort(_ port: Int) -> String? {
        // Try to get AVD name by connecting to emulator console
        // For now, return nil - this requires telnet which is complex
        // The AVD name will be shown when we implement AVDManager
        return nil
    }

    func install(serial: String, apkPath: URL) async throws {
        let adb = try getADBPath()
        do {
            try await shell(adb, "-s", serial, "install", "-r", apkPath.path)
        } catch let error as ShellError {
            throw SparklyError.installationFailed(apkPath.lastPathComponent, underlying: error)
        }
    }

    func uninstall(serial: String, packageName: String) async throws {
        let adb = try getADBPath()
        do {
            try await shell(adb, "-s", serial, "uninstall", packageName)
        } catch {
            // Ignore errors - package might not be installed
        }
    }

    func launch(serial: String, packageName: String, activityName: String? = nil) async throws {
        let adb = try getADBPath()

        // If activity name is provided, launch specific activity
        // Otherwise, use monkey to launch the main activity
        if let activity = activityName {
            try await shell(adb, "-s", serial, "shell", "am", "start", "-n", "\(packageName)/\(activity)")
        } else {
            try await shell(adb, "-s", serial, "shell", "monkey", "-p", packageName, "-c", "android.intent.category.LAUNCHER", "1")
        }
    }

    func getDeviceProperty(serial: String, property: String) async throws -> String? {
        let adb = try getADBPath()
        let data = try await shell(adb, "-s", serial, "shell", "getprop", property)
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getAndroidVersion(serial: String) async throws -> String? {
        try await getDeviceProperty(serial: serial, property: "ro.build.version.release")
    }

    func getAPILevel(serial: String) async throws -> String? {
        try await getDeviceProperty(serial: serial, property: "ro.build.version.sdk")
    }

    func listInstalledApps(serial: String) async throws -> [InstalledApp] {
        let adb = try getADBPath()
        let data = try await shell(adb, "-s", serial, "shell", "pm", "list", "packages", "-3")

        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return parsePackageList(output)
    }

    private func parsePackageList(_ output: String) -> [InstalledApp] {
        // Output format: package:com.example.app
        let lines = output.components(separatedBy: .newlines)

        return lines.compactMap { line -> InstalledApp? in
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix("package:") else { return nil }

            let packageName = String(trimmed.dropFirst("package:".count))
            guard !packageName.isEmpty else { return nil }

            return InstalledApp(
                bundleID: packageName,
                name: packageName.components(separatedBy: ".").last ?? packageName,
                platform: .android
            )
        }.sorted { $0.bundleID.localizedCaseInsensitiveCompare($1.bundleID) == .orderedAscending }
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
