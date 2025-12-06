import Foundation
import Observation

@Observable
final class DeviceListViewModel: @unchecked Sendable {
    private(set) var simulators: [SimulatorDevice] = []
    private(set) var emulators: [EmulatorDevice] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

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

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Fetch iOS simulators and Android emulators in parallel
        async let simulatorsTask = fetchSimulators()
        async let emulatorsTask = fetchEmulators()

        let (sims, emus) = await (simulatorsTask, emulatorsTask)
        simulators = sims
        emulators = emus

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
    func launchAVD(_ avdName: String) async {
        do {
            try await avdManager.launchAVD(name: avdName)
            // Wait a bit for emulator to start, then refresh
            try? await Task.sleep(for: .seconds(3))
            await refresh()
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
