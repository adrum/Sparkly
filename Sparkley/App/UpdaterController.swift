//
//  UpdaterController.swift
//  Sparkley
//
//  Created by Austin Drummond on 12/6/25.
//

import Combine
import Foundation
import Sparkle
import SwiftUI

final class UpdaterController: ObservableObject {
    private let updaterController: SPUStandardUpdaterController

    @Published var canCheckForUpdates = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

struct CheckForUpdatesView: View {
    @ObservedObject var updaterController: UpdaterController

    var body: some View {
        Button("Check for Updates...") {
            updaterController.checkForUpdates()
        }
        .disabled(!updaterController.canCheckForUpdates)
    }
}
