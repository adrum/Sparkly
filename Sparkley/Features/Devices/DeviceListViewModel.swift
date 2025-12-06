import Foundation
import Observation

@Observable
final class DeviceListViewModel: @unchecked Sendable {
    private(set) var devices: [SimulatorDevice] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    var selectedDevice: SimulatorDevice?

    private let simctlService: SimctlService

    var bootedDevices: [SimulatorDevice] {
        devices.filter { $0.isBooted }
    }

    var availableDevices: [SimulatorDevice] {
        devices.filter { !$0.isBooted }
    }

    var devicesByRuntime: [String: [SimulatorDevice]] {
        Dictionary(grouping: devices) { $0.runtimeDisplayName }
    }

    init(simctlService: SimctlService) {
        self.simctlService = simctlService
    }

    @MainActor
    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            devices = try await simctlService.listDevices()

            if selectedDevice == nil {
                selectedDevice = bootedDevices.first ?? devices.first
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

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

    func selectFirstBootedDevice() {
        selectedDevice = bootedDevices.first ?? devices.first
    }
}
