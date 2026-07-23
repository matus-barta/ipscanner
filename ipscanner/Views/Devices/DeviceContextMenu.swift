//
//  DeviceContextMenu.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//

import SwiftUI

struct DeviceContextMenu: View {
    let device: Device

    var body: some View {
        copySection

        if hasConnectionActions {
            Divider()
            connectionSection
        }
    }

    @ViewBuilder
    private var copySection: some View {
        if let hostname = device.hostname,
           !hostname.isEmpty
        {
            Button(
                "Copy Hostname",
                systemImage: "doc.on.doc"
            ) {
                DeviceActions.copyHostname(
                    for: device
                )
            }
        }

        Button(
            "Copy IP Address",
            systemImage: "doc.on.doc"
        ) {
            DeviceActions.copyIPAddress(
                for: device
            )
        }

        if let mac = device.mac,
           !mac.isEmpty
        {
            Button(
                "Copy MAC Address",
                systemImage: "doc.on.doc"
            ) {
                DeviceActions.copyMACAddress(
                    for: device
                )
            }
        }

        if let manufacturer = device.manufacturer,
           !manufacturer.isEmpty
        {
            Button(
                "Copy Manufacturer",
                systemImage: "doc.on.doc"
            ) {
                DeviceActions.copyManufacturer(
                    for: device
                )
            }
        }
    }

    @ViewBuilder
    private var connectionSection: some View {
        if hasWebInterface {
            Button(
                webInterfaceLabel,
                systemImage: "globe"
            ) {
                DeviceActions.openWebInterface(
                    for: device
                )
            }
        }

        if device.openPorts.contains(22) {
            Button(
                "Connect with SSH",
                systemImage: "terminal"
            ) {
                DeviceActions.openSSH(
                    for: device
                )
            }
        }

        if device.openPorts.contains(5900) {
            Button(
                "Open Screen Sharing",
                systemImage: "display"
            ) {
                DeviceActions.openScreenSharing(
                    for: device
                )
            }
        }
    }

    private var hasWebInterface: Bool {
        !device.openPorts.isDisjoint(
            with: [
                80,
                443,
                8000,
                8006,
                8080,
                8081,
                8443,
            ]
        )
    }

    private var hasConnectionActions: Bool {
        hasWebInterface
            || device.openPorts.contains(22)
            || device.openPorts.contains(5900)
    }

    private var webInterfaceLabel: String {
        if device.openPorts.contains(443) {
            return "Open HTTPS Interface"
        }

        if device.openPorts.contains(80) {
            return "Open HTTP Interface"
        }

        return "Open Web Interface"
    }
}
