//
//  ScannerCommands.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//

import SwiftUI

struct ScannerCommands: Commands {
    let scanner: Scanner
    let appState: AppState

    private var selectedDevice: Device? {
        scanner.device(
            withID: appState.selectedDeviceID
        )
    }

    var body: some Commands {
        scanCommands
        deviceCommands
        viewCommands
    }

    // MARK: - Scan menu

    private var scanCommands: some Commands {
        CommandMenu("Scan") {
            Button(
                "Start Scan",
                systemImage: "play.fill"
            ) {
                scanner.startScan()
            }
            .keyboardShortcut(
                "r",
                modifiers: .command
            )
            .disabled(
                scanner.isScanning ||
                    scanner.subnetList.isEmpty
            )

            Button(
                "Stop Scan",
                systemImage: "stop.fill"
            ) {
                scanner.stopScan()
            }
            .keyboardShortcut(
                ".",
                modifiers: .command
            )
            .disabled(!scanner.isScanning)

            Divider()

            Button(
                "Refresh Interfaces",
                systemImage: "arrow.clockwise"
            ) {
                scanner.refreshInterfaces()
            }
            .keyboardShortcut(
                "r",
                modifiers: [
                    .command,
                    .shift,
                ]
            )
            .disabled(scanner.isScanning)

            Divider()

            Button(
                "Clear Results",
                systemImage: "trash"
            ) {
                appState.clearSelection()
                appState.inspectorPresented = false
                scanner.clearResults()
            }
            .disabled(
                scanner.devices.isEmpty ||
                    scanner.isScanning
            )
        }
    }

    // MARK: - Device menu

    private var deviceCommands: some Commands {
        CommandMenu("Device") {
            Button(
                "Copy IP Address",
                systemImage: "doc.on.doc"
            ) {
                guard let selectedDevice else {
                    return
                }

                DeviceActions.copyIPAddress(
                    for: selectedDevice
                )
            }
            .keyboardShortcut(
                "c",
                modifiers: [
                    .command,
                    .shift,
                ]
            )
            .disabled(selectedDevice == nil)

            Divider()

            Button(
                "Open Web Interface",
                systemImage: "globe"
            ) {
                guard let selectedDevice else {
                    return
                }

                DeviceActions.openWebInterface(
                    for: selectedDevice
                )
            }
            .disabled(
                selectedDevice.map {
                    !hasWebInterface($0)
                } ?? true
            )

            Button(
                "Connect with SSH",
                systemImage: "terminal"
            ) {
                guard let selectedDevice else {
                    return
                }

                DeviceActions.openSSH(
                    for: selectedDevice
                )
            }
            .disabled(
                selectedDevice?
                    .openPorts
                    .contains(22) != true
            )

            Button(
                "Open Screen Sharing",
                systemImage: "display"
            ) {
                guard let selectedDevice else {
                    return
                }

                DeviceActions.openScreenSharing(
                    for: selectedDevice
                )
            }
            .disabled(
                selectedDevice?
                    .openPorts
                    .contains(5900) != true
            )
        }
    }

    // MARK: - View menu

    private var viewCommands: some Commands {
        CommandGroup(after: .toolbar) {
            Button(
                appState.inspectorPresented
                    ? "Hide Inspector"
                    : "Show Inspector",
                systemImage: "sidebar.right"
            ) {
                appState.toggleInspector()
            }
            .keyboardShortcut(
                "i",
                modifiers: [
                    .command,
                    .option,
                ]
            )

            Button(
                "Focus Search",
                systemImage: "magnifyingglass"
            ) {
                appState.focusSearch()
            }
            .keyboardShortcut(
                "f",
                modifiers: .command
            )
        }
    }

    // MARK: - Helpers

    private func hasWebInterface(
        _ device: Device
    ) -> Bool {
        !device.openPorts.isDisjoint(
            with: [
                80,
                443,
                8000,
                8006,
                8008,
                8009,
                8080,
                8081,
                8443,
            ]
        )
    }
}
