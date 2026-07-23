//
//  DeviceTableView.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
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
            TableColumn("MAC address", value: \.macSort)
            TableColumn("Manufacturer", value: \.manufacturerSort)
        } rows: {
            ForEach(devices) { device in
                TableRow(device)
                    .contextMenu {
                        DeviceContextMenu(device: device)
                    }
            }
        }
    }
}
