//
//  IpScannerIPadApp.swift
//  ipscanner
//
//  Created by Matúš Barta on 25/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
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
