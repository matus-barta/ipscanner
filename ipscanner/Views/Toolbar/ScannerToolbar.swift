//
//  ScannerToolbar.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//
import SwiftUI

struct ScannerToolbar: ToolbarContent {
    @Environment(Scanner.self) private var scanner

    @Binding var inspectorPresented: Bool

    var body: some ToolbarContent {
        @Bindable var scanner = scanner

        ToolbarItem {
            Button(
                scanner.isScanning ? "Stop" : "Scan",
                systemImage: scanner.isScanning ? "stop.fill" : "play.fill"
            ) {
                if scanner.isScanning {
                    scanner.stopScan()
                } else {
                    scanner.startScan()
                }
            }
            .labelStyle(.titleAndIcon)
            .buttonStyle(.glass)
            .tint(
                scanner.isScanning
                    ? Color.red.opacity(0.75)
                    : Color.green.opacity(0.75)
            )
            .keyboardShortcut(.defaultAction)
        }
        ToolbarItem {
            Button(
                "Pause",
                systemImage: "pause.fill",
                action: scanner.pauseScan
            )
            .disabled(true)
        }
        ToolbarItem {
            Picker(
                "Profile",
                selection: $scanner.scanProfile
            ) {
                ForEach(ScanProfile.allCases) { profile in
                    Text("\(profile.displayName) (\(profile.portCount))")
                        .tag(profile)
                }
            }
        }
        ToolbarItem {
            Picker(
                "Timeout",
                selection: $scanner.connectionTimeout
            ) {
                Text("0.25s").tag(0.25)
                Text("0.5s").tag(0.5)
                Text("1.0s").tag(1.0)
                Text("2.0s").tag(2.0)
            }
        }
        ToolbarItem {
            Button(
                "Inspector",
                systemImage: inspectorPresented
                    ? "sidebar.right"
                    : "sidebar.right"
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    inspectorPresented.toggle()
                }
            }
            .help(
                inspectorPresented
                    ? "Hide Inspector"
                    : "Show Inspector"
            )
        }
    }
}
