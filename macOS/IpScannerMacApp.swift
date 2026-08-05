//
//  IpScannerMacApp.swift
//  ipscanner
//
//  Created by Matúš Barta on 25/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

@main
struct IpScannerMacApp: App {
    @State private var scanner = Scanner()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView(
                scanner: scanner,
                appState: appState
            )
            .frame(
                minWidth: 900,
                maxWidth: .infinity,
                minHeight: 500,
                maxHeight: .infinity
            )
        }
        .defaultSize(
            width: 900,
            height: 500
        )
        .windowResizability(.contentSize)
        .commands {
            ExportCommands(
                scanner: scanner
            )

            ScannerCommands(
                scanner: scanner,
                appState: appState
            )
        }

        Settings {
            SettingsView()
        }
    }
}
