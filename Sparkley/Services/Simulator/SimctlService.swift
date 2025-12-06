import Foundation

actor SimctlService {
    func listDevices() async throws -> [SimulatorDevice] {
        // Use text parsing to handle duplicate runtime keys bug in Xcode 26 beta
        // The JSON output has duplicate keys which Swift's JSONDecoder merges incorrectly
        let data = try await shell("xcrun", "simctl", "list", "devices")
        guard let output = String(data: data, encoding: .utf8) else {
            throw SparkleyError.simulatorNotFound("Failed to parse simctl output")
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
            throw SparkleyError.simulatorBootFailed(udid, underlying: error)
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
            throw SparkleyError.installationFailed(appPath.lastPathComponent, underlying: error)
        }
    }

    func launch(udid: String, bundleID: String) async throws {
        do {
            try await shell("xcrun", "simctl", "launch", udid, bundleID)
        } catch let error as ShellError {
            throw SparkleyError.launchFailed(bundleID, underlying: error)
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
}
