import Foundation
import Observation

@Observable
final class DeviceListViewModel: @unchecked Sendable {
    private(set) var simulators: [SimulatorDevice] = []
    private(set) var emulators: [EmulatorDevice] = []
    private(set) var availableAVDs: [AVDInfo] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var launchingAVDs: Set<String> = []

    var selectedDevice: AnyDevice?

    private let simctlService: SimctlService
    private let adbService: ADBService
    private let avdManager: AVDManager

    /// All devices as unified AnyDevice array
    var allDevices: [AnyDevice] {
        let sims = simulators.map { AnyDevice.simulator($0) }
        let emus = emulators.map { AnyDevice.emulator($0) }
        return sims + emus
    }

    /// Legacy compatibility - returns simulators
    var devices: [SimulatorDevice] { simulators }

    var bootedSimulators: [SimulatorDevice] {
        simulators.filter { $0.isBooted }
    }

    var onlineEmulators: [EmulatorDevice] {
        emulators.filter { $0.isOnline }
    }

    var isAndroidAvailable: Bool {
        Task.init { await adbService.isAvailable() }
        // Sync check - just check if we have any emulators loaded
        return !emulators.isEmpty || adbService.isAvailable()
    }

    init(simctlService: SimctlService, adbService: ADBService = ADBService(), avdManager: AVDManager = AVDManager()) {
        self.simctlService = simctlService
        self.adbService = adbService
        self.avdManager = avdManager
    }

    /// Available AVDs that are not currently running
    var launchableAVDs: [AVDInfo] {
        let runningAVDNames = Set(emulators.compactMap { $0.avdName })
        return availableAVDs.filter { !runningAVDNames.contains($0.name) }
    }

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Fetch iOS simulators, Android emulators, and available AVDs in parallel
        async let simulatorsTask = fetchSimulators()
        async let emulatorsTask = fetchEmulators()
        async let avdsTask = fetchAvailableAVDs()

        let (sims, emus, avds) = await (simulatorsTask, emulatorsTask, avdsTask)
        simulators = sims
        emulators = emus
        availableAVDs = avds

        // Auto-select first ready device if none selected
        if selectedDevice == nil {
            if let booted = bootedSimulators.first {
                selectedDevice = .simulator(booted)
            } else if let online = onlineEmulators.first {
                selectedDevice = .emulator(online)
            } else if let firstSim = simulators.first {
                selectedDevice = .simulator(firstSim)
            } else if let firstEmu = emulators.first {
                selectedDevice = .emulator(firstEmu)
            }
        }
    }

    private func fetchSimulators() async -> [SimulatorDevice] {
        do {
            return try await simctlService.listDevices()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
            }
            return []
        }
    }

    private func fetchEmulators() async -> [EmulatorDevice] {
        guard await adbService.isAvailable() else { return [] }

        do {
            return try await adbService.listDevices()
        } catch {
            // Don't show error for Android - it's optional
            return []
        }
    }

    private func fetchAvailableAVDs() async -> [AVDInfo] {
        guard await avdManager.isAvailable() else { return [] }

        do {
            return try await avdManager.listAVDs()
        } catch {
            // Don't show error for AVDs - it's optional
            return []
        }
    }

    // MARK: - iOS Simulator Actions

    @MainActor
    func boot(_ device: SimulatorDevice) async {
        do {
            try await simctlService.boot(udid: device.udid)
            try await simctlService.openSimulatorApp()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func shutdown(_ device: SimulatorDevice) async {
        do {
            try await simctlService.shutdown(udid: device.udid)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func openSimulatorApp() async {
        do {
            try await simctlService.openSimulatorApp()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Android Emulator Actions

    @MainActor
    func killEmulator(_ device: EmulatorDevice) async {
        do {
            try await avdManager.killEmulator(serial: device.serial)
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func launchAVD(_ avdName: String, coldBoot: Bool = false) async {
        launchingAVDs.insert(avdName)
        defer { launchingAVDs.remove(avdName) }

        do {
            try await avdManager.launchAVD(name: avdName, coldBoot: coldBoot)
            // Wait a bit for emulator to start, then refresh
            try? await Task.sleep(for: .seconds(3))
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func isLaunchingAVD(_ name: String) -> Bool {
        launchingAVDs.contains(name)
    }

    // MARK: - App Management

    func listInstalledApps(on device: AnyDevice) async -> [InstalledApp] {
        switch device {
        case .simulator(let sim):
            guard sim.isBooted else { return [] }
            do {
                return try await simctlService.listInstalledApps(udid: sim.udid)
            } catch {
                return []
            }
        case .emulator(let emu):
            guard emu.isOnline else { return [] }
            do {
                return try await adbService.listInstalledApps(serial: emu.serial)
            } catch {
                return []
            }
        }
    }

    @MainActor
    func launchApp(_ app: InstalledApp, on device: AnyDevice) async {
        do {
            switch device {
            case .simulator(let sim):
                try await simctlService.launch(udid: sim.udid, bundleID: app.bundleID)
            case .emulator(let emu):
                try await adbService.launch(serial: emu.serial, packageName: app.bundleID)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectFirstBootedDevice() {
        if let booted = bootedSimulators.first {
            selectedDevice = .simulator(booted)
        } else if let online = onlineEmulators.first {
            selectedDevice = .emulator(online)
        } else if let firstSim = simulators.first {
            selectedDevice = .simulator(firstSim)
        }
    }
}
