//
//  IpScannerApp.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import SwiftUI

@main
struct IpScannerApp: App {
    @State private var scanner = Scanner()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView().frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity, alignment: .center)
        }
        .defaultSize(width: 900, height: 500)
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
        .environment(scanner)
        .environment(appState)

        Settings {
            SettingsView()
        }
    }
}
