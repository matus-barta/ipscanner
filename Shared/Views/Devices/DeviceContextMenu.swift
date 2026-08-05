//
//  DeviceContextMenu.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
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

        #if os(macOS)
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
        #endif
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
                sshButtonTitle,
                systemImage: "terminal"
            ) {
                DeviceActions.openSSH(
                    for: device
                )
            }
        }
        #if os(macOS)
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
        #endif
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
        #if os(macOS)
            hasWebInterface
                || device.openPorts.contains(22)
                || device.openPorts.contains(5900)
        #else
            hasWebInterface
                || device.openPorts.contains(22)
        #endif
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

    private var sshButtonTitle: String {
        #if os(macOS)
            "Connect with SSH"
        #else
            "Open in SSH App"
        #endif
    }
}
