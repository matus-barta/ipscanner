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
            ContentView()
                .environmentObject(RustAppWrapper(rust: RustApp()))
                .frame(minWidth: 700, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity, alignment: .center)
        }
        .defaultSize(width: 700, height: 500)
                .windowResizability(.contentSize)
    }
}

class RustAppWrapper: ObservableObject {    
    @Published var rust: RustApp

    init (rust: RustApp) {
        self.rust = rust
    }
}
