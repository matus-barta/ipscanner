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

    var body: some Scene {
        WindowGroup {
            ContentView().frame(minWidth: 900, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity, alignment: .center)
        }
        .defaultSize(width: 900, height: 500)
        .windowResizability(.contentSize)
        .environment(scanner)
    }
}
