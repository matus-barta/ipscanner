//
//  DeviceInspectorView.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

struct DeviceInspectorView: View {
    let device: Device?

    var body: some View {
        Group {
            if let device {
                DeviceDetailsView(device: device)
            } else {
                ContentUnavailableView(
                    "No Device Selected",
                    systemImage: "network",
                    description: Text(
                        "Select a device to view its identity and services."
                    )
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

private struct DeviceDetailsView: View {
    let device: Device

    var body: some View {
        Form {
            identitySection
            servicesSection
        }
        .formStyle(.grouped)
    }

    private var identitySection: some View {
        Section("Identity") {
            CopyableLabeledContent("Hostname", value: device.hostname)

            LabeledContent("Name source") {
                if let source = device.hostnameSource {
                    Label(
                        source.displayName,
                        systemImage: source.systemImage
                    )
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.secondary)
                } else {
                    Text("Unknown")
                        .foregroundStyle(.secondary)
                }
            }

            CopyableLabeledContent("IP address", value: device.ip, monospaced: true)

            #if os(macOS)
                CopyableLabeledContent("MAC address", value: device.mac, monospaced: true)

                LabeledContent("Manufacturer") {
                    Text(device.manufacturer ?? "Unknown")
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            #endif
        }
    }

    private var servicesSection: some View {
        Section {
            if device.openPorts.isEmpty {
                ContentUnavailableView(
                    "No Open Ports",
                    systemImage: "lock.fill",
                    description: Text(
                        "No open TCP ports were found in the selected scan profile."
                    )
                )
                .frame(maxWidth: .infinity)
            } else {
                ForEach(
                    device.openPorts.sorted(),
                    id: \.self
                ) { port in
                    PortServiceRow(port: port)
                }
            }
        } header: {
            HStack {
                Text("Open Services")

                Spacer()

                Text("\(device.openPorts.count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

private struct PortServiceRow: View {
    let port: UInt16

    private var serviceName: String {
        PortDatabase.name(for: port) ?? "Unknown service"
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: serviceIcon)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(serviceName)

                Text("TCP port \(port)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            Text("\(port)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }

    private var serviceIcon: String {
        switch port {
        case 20, 21:
            "arrow.left.arrow.right"

        case 22:
            "terminal"

        case 23:
            "rectangle.connected.to.line.below"

        case 25, 110, 143, 465, 587, 993, 995:
            "envelope"

        case 53:
            "network"

        case 80, 443, 8000, 8006, 8008, 8009,
             8080, 8081, 8443, 8888:
            "globe"

        case 111:
            "point.3.connected.trianglepath.dotted"

        case 123:
            "clock"

        case 135, 137, 138, 139, 445:
            "folder"

        case 161, 162:
            "waveform.path.ecg"

        case 389, 636:
            "person.2"

        case 515, 631, 9100:
            "printer"

        case 548, 2049:
            "externaldrive"

        case 554, 8554:
            "video"

        case 902, 903:
            "square.stack.3d.up"

        case 1433, 1434, 1521, 3306, 5432,
             6379, 27017, 27018, 27019:
            "cylinder"

        case 1883, 5672:
            "ellipsis.message"

        case 2375, 2376, 6443:
            "shippingbox"

        case 3389, 5900:
            "display"

        case 3493:
            "battery.100percent"

        case 5353:
            "dot.radiowaves.left.and.right"

        case 5555:
            "apps.iphone"

        case 5985, 5986:
            "gearshape.2"

        case 1900:
            "antenna.radiowaves.left.and.right"

        case 32400:
            "play.rectangle"

        default:
            "network"
        }
    }
}

#Preview("Selected device") {
    DeviceInspectorView(
        device: Device(
            ip: "192.168.22.9",
            hostname: "desktop.example.local",
            hostnameSource: .reverseDNS,
            mac: "0C:9D:92:79:5E:65",
            manufacturer: "ASUSTek Computer Inc.",
            openPorts: [
                22,
                80,
                443,
                445,
                3389,
            ]
        )
    )
    .frame(
        width: 320,
        height: 600
    )
}

#Preview("No selection") {
    DeviceInspectorView(device: nil)
        .frame(
            width: 320,
            height: 600
        )
}
