//
//  ScannerToolbar.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

struct ScannerToolbar: ToolbarContent {
    @Environment(Scanner.self) private var scanner

    @Binding var inspectorPresented: Bool

    var body: some ToolbarContent {
        @Bindable var scanner = scanner

        #if os(macOS)
            ToolbarItem {
                scanButton
                    .buttonStyle(.glass)
                    .tint(scanner.isScanning ? Color.red.opacity(0.75) : Color.green.opacity(0.75))
            }
        #else
            ToolbarItem(placement: .topBarLeading) {
                scanButton
                    .buttonStyle(.glassProminent)
                    .tint(scanner.isScanning ? .red : .green)
                    .controlSize(.large)
            }
        #endif
        ToolbarItemGroup(placement: .primaryAction) {
            Button(
                "Pause",
                systemImage: "pause.fill",
                action: scanner.pauseScan
            )
            .disabled(true)

            Picker(
                "Profile",
                selection: $scanner.scanProfile
            ) {
                ForEach(ScanProfile.allCases) { profile in
                    Text("\(profile.displayName) (\(profile.portCount))")
                        .tag(profile)
                }
            }

            Picker(
                "Timeout",
                selection: $scanner.connectionTimeout
            ) {
                Text("0.25s").tag(0.25)
                Text("0.5s").tag(0.5)
                Text("1.0s").tag(1.0)
                Text("2.0s").tag(2.0)
            }

            Button(
                "Inspector",
                systemImage: inspectorPresented
                    ? "sidebar.right"
                    : "sidebar.right"
            ) {
                inspectorPresented.toggle()
            }
            .help(
                inspectorPresented
                    ? "Hide Inspector"
                    : "Show Inspector"
            )
        }
    }

    private var scanButton: some View {
        Button(
            scanner.isScanning ? "Stop" : "Scan",
            systemImage: scanner.isScanning
                ? "stop.fill"
                : "play.fill"
        ) {
            if scanner.isScanning {
                scanner.stopScan()
            } else {
                scanner.startScan()
            }
        }
        .labelStyle(.titleAndIcon)
        .fixedSize()
        .keyboardShortcut(.defaultAction)
        .disabled(
            !scanner.isScanning &&
                scanner.subnetList.isEmpty
        )
        .help(scanner.isScanning ? "Stop Scan" : "Start Scan")
    }
}
