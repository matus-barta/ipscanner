//
//  AppRootView.swift
//  ipscanner
//
//  Created by Matúš Barta on 25/07/2026.
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
