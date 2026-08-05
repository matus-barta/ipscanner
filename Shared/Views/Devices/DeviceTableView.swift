//
//  DeviceTableView.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

struct DeviceTableView: View {
    @Environment(Scanner.self) private var scanner

    @Binding var selection: Device.ID?
    @Binding var sortOrder: [KeyPathComparator<Device>]

    let devices: [Device]

    var body: some View {
        Table(of: Device.self, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Hostname", value: \.hostnameSort)
            TableColumn("IP address", value: \.ip)
            TableColumn("Open ports", value: \.openPortsDisplay)
            #if os(macOS)
                TableColumn("MAC address", value: \.macSort)
                TableColumn("Manufacturer", value: \.manufacturerSort)
            #else
                TableColumn("") { device in deviceActionsMenu(for: device) }
                    .width(44)
            #endif
        } rows: {
            ForEach(devices) { device in
                TableRow(device)
                    .contextMenu {
                        DeviceContextMenu(device: device)
                    }
            }
        }
    }

    #if os(iOS)
        private func deviceActionsMenu(for device: Device) -> some View {
            Menu {
                DeviceContextMenu(device: device)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .contentShape(Circle())
            }
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .accessibilityLabel("Actions for \(device.hostname ?? device.ip)")
            .help("Device actions")
        }
    #endif
}
