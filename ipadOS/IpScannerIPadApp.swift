//
//  IpScannerIPadApp.swift
//  ipscanner
//
//  Created by Matúš Barta on 25/07/2026.
//

import SwiftUI

@main
struct IpScannerIPadApp: App {
    @State private var scanner = Scanner()
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                AppRootView(
                    scanner: scanner,
                    appState: appState
                )
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
