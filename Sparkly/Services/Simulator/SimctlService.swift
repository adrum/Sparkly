import Foundation

actor SimctlService {
    func listDevices() async throws -> [SimulatorDevice] {
        // Use text parsing to handle duplicate runtime keys bug in Xcode 26 beta
        // The JSON output has duplicate keys which Swift's JSONDecoder merges incorrectly
        let data = try await shell("xcrun", "simctl", "list", "devices")
        guard let output = String(data: data, encoding: .utf8) else {
            throw SparklyError.simulatorNotFound("Failed to parse simctl output")
        }

        return parseDevicesText(output)
    }

    private func parseDevicesText(_ output: String) -> [SimulatorDevice] {
        var devices: [SimulatorDevice] = []
        var currentRuntime: String?

        let lines = output.components(separatedBy: .newlines)

        for line in lines {
            // Runtime header: "-- iOS 26.0 --"
            if line.hasPrefix("--") && line.hasSuffix("--") {
                let runtime = line
                    .trimmingCharacters(in: CharacterSet(charactersIn: "- "))
                    .trimmingCharacters(in: .whitespaces)
                currentRuntime = runtime
                continue
            }

            // Device line: "    iPhone 17 Pro (E2DA1C4A-B7F6-438E-BBB0-D3E3972703B9) (Shutdown)"
            guard let runtime = currentRuntime else { continue }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Parse: "DeviceName (UDID) (State)" or "DeviceName (UDID) (State) (unavailable...)"
            // Regex pattern to match device lines
            let pattern = #"^(.+?) \(([A-F0-9\-]{36})\) \((\w+(?:\s+\w+)?)\)"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
                  let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)) else {
                continue
            }

            guard let nameRange = Range(match.range(at: 1), in: trimmed),
                  let udidRange = Range(match.range(at: 2), in: trimmed),
                  let stateRange = Range(match.range(at: 3), in: trimmed) else {
                continue
            }

            let name = String(trimmed[nameRange])
            let udid = String(trimmed[udidRange])
            let stateStr = String(trimmed[stateRange])

            // Skip unavailable devices
            if trimmed.contains("unavailable") {
                continue
            }

            let state = SimulatorDevice.DeviceState(rawValue: stateStr) ?? .unknown

            let device = SimulatorDevice(
                udid: udid,
                name: name,
                deviceTypeIdentifier: "",  // Not available in text output
                runtime: runtime,
                state: state,
                isAvailable: true
            )
            devices.append(device)
        }

        return devices.sorted { device1, device2 in
            if device1.runtime != device2.runtime {
                return device1.runtime > device2.runtime
            }
            return device1.name.localizedCaseInsensitiveCompare(device2.name) == .orderedAscending
        }
    }

    func boot(udid: String) async throws {
        do {
            try await shell("xcrun", "simctl", "boot", udid)
        } catch let error as ShellError {
            throw SparklyError.simulatorBootFailed(udid, underlying: error)
        }
    }

    func shutdown(udid: String) async throws {
        do {
            try await shell("xcrun", "simctl", "shutdown", udid)
        } catch {
            // Ignore errors when shutting down - device might already be shut down
        }
    }

    func install(udid: String, appPath: URL) async throws {
        do {
            try await shell("xcrun", "simctl", "install", udid, appPath.path)
        } catch let error as ShellError {
            throw SparklyError.installationFailed(appPath.lastPathComponent, underlying: error)
        }
    }

    func launch(udid: String, bundleID: String) async throws {
        do {
            try await shell("xcrun", "simctl", "launch", udid, bundleID)
        } catch let error as ShellError {
            throw SparklyError.launchFailed(bundleID, underlying: error)
        }
    }

    func uninstall(udid: String, bundleID: String) async throws {
        do {
            try await shell("xcrun", "simctl", "uninstall", udid, bundleID)
        } catch {
            // Ignore errors - app might not be installed
        }
    }

    func openSimulatorApp() async throws {
        try await shell("open", "-a", "Simulator")
    }

    func getBootedDevices() async throws -> [SimulatorDevice] {
        let devices = try await listDevices()
        return devices.filter { $0.isBooted }
    }

    func listInstalledApps(udid: String) async throws -> [InstalledApp] {
        let data = try await shell("xcrun", "simctl", "listapps", udid)
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }
        return parseInstalledApps(output)
    }

    private func parseInstalledApps(_ output: String) -> [InstalledApp] {
        var apps: [InstalledApp] = []

        // The output is a plist-style format, parse bundle IDs and names
        let lines = output.components(separatedBy: .newlines)
        var currentBundleID: String?
        var currentName: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.contains("CFBundleIdentifier") {
                // Next line should have the value
                if let nextIndex = lines.firstIndex(where: { $0.contains(trimmed) }),
                   nextIndex + 1 < lines.count {
                    let valueLine = lines[nextIndex + 1]
                    if let start = valueLine.range(of: "<string>"),
                       let end = valueLine.range(of: "</string>") {
                        currentBundleID = String(valueLine[start.upperBound..<end.lowerBound])
                    }
                }
            }

            if trimmed.hasPrefix("<key>CFBundleIdentifier</key>") {
                continue
            }

            // Look for pattern: CFBundleIdentifier = "com.example.app";
            if trimmed.contains("CFBundleIdentifier") && trimmed.contains("=") {
                let parts = trimmed.components(separatedBy: "=")
                if parts.count >= 2 {
                    var value = parts[1].trimmingCharacters(in: .whitespaces)
                    value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
                    value = value.replacingOccurrences(of: "\"", with: "")
                    if !value.isEmpty {
                        currentBundleID = value
                    }
                }
            }

            if trimmed.contains("CFBundleDisplayName") || trimmed.contains("CFBundleName") {
                let parts = trimmed.components(separatedBy: "=")
                if parts.count >= 2 {
                    var value = parts[1].trimmingCharacters(in: .whitespaces)
                    value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\";"))
                    value = value.replacingOccurrences(of: "\"", with: "")
                    if !value.isEmpty && currentName == nil {
                        currentName = value
                    }
                }
            }

            // When we hit a closing brace, save the app if we have a bundle ID
            if trimmed == "}" || trimmed == "}," {
                if let bundleID = currentBundleID, !bundleID.hasPrefix("com.apple.") {
                    let app = InstalledApp(
                        bundleID: bundleID,
                        name: currentName ?? bundleID,
                        platform: .ios
                    )
                    apps.append(app)
                }
                currentBundleID = nil
                currentName = nil
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
