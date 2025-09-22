//
//  ipscannerApp.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import SwiftUI

@main
struct ipscannerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView().frame(minWidth: 700, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity, alignment: .center)
        }
        .defaultSize(width: 700, height: 500)
                .windowResizability(.contentSize)
    }
}
