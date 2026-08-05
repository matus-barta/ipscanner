//
//  AppRootView.swift
//  ipscanner
//
//  Created by Matúš Barta on 25/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

struct AppRootView: View {
    let scanner: Scanner
    let appState: AppState

    var body: some View {
        ContentView()
            .environment(scanner)
            .environment(appState)
    }
}
