//
//  DeviceInspectorView.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//

import SwiftUI

struct DeviceInspectorView: View {
    let device: Device?

    var body: some View {
        if let device {
            Form {
                Section("Identity") {
                    LabeledContent("Hostname") {
                        Text(device.hostname ?? "-")
                    }

                    LabeledContent("IP") {
                        Text(device.ip)
                    }

                    LabeledContent("MAC") {
                        Text(device.mac ?? "-")
                    }

                    LabeledContent("Vendor") {
                        Text(device.manufacturer ?? "-")
                    }
                }

                Section("Services") {
                    Text(device.openPortsDisplay)
                }
            }
        } else {
            ContentUnavailableView(
                "No Device Selected",
                systemImage: "network"
            )
        }
    }
}
