//
//  ContentView.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var devices: [Device] = [
        Device(
            ip: "192.168.0.22",
            mac: "22-22-22-22-22",
            manufacturer: "Apple",
            name: "mac.local"
        ),
        Device(
            ip: "192.168.0.23",
            mac: "22-22-22-22-23",
            manufacturer: "Apple",
            name: "mac2.local"
        ),
        Device(
            ip: "192.168.0.23",
            mac: "22-22-22-22-23",
            manufacturer: "Apple",
            name: "mac2.local"
        ),
        Device(
            ip: "192.168.0.23",
            mac: "22-22-22-22-23",
            manufacturer: "Apple",
            name: "mac2.local"
        ),
    ]

    @State private var sortOrder: [KeyPathComparator<Device>] = [
        .init(\.ip, order: SortOrder.forward)
    ]

    @State private var selection: Device.ID? = nil  //Set<Device.ID> = [] - multiple
    @State private var search = ""
    @State private var currentValue = 0.6

    var body: some View {
        VStack(spacing: 10) {
            Table(of: Device.self, selection: $selection, sortOrder: $sortOrder)
            {
                TableColumn("Name", value: \.name)
                TableColumn("IP", value: \.ip)
                TableColumn("Mac", value: \.mac)
                TableColumn("Manufacturer", value: \.manufacturer)
            } rows: {
                ForEach(devices) { device in
                    TableRow(device)
                        .contextMenu {
                            Button("Stuff1") {

                            }
                            Button("Stuff2") {

                            }
                            Divider()
                            Button(role: .destructive) {

                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .onChange(of: sortOrder) {
                devices.sort(using: sortOrder)
            }
            .searchable(text: $search)
            .toolbar {
                ToolbarItem {
                    Button("Scan", systemImage: "play.fill", action: startScan)
                    .labelStyle(.titleAndIcon)
                    .buttonStyle(.glassProminent)
                    .tint(.green)
                }
                ToolbarSpacer(.fixed)
                ToolbarItem {
                    Button(
                        "Pause",
                        systemImage: "pause.fill",
                        action: pauseScan
                    )
                    .disabled(true)
                }

            }

            Gauge(value: currentValue, in: 0.0...1.0) {
                Text("Scanning")
            } currentValueLabel: {
                Text("\(Int(currentValue*100)) out of 100")
            }.gaugeStyle(
                .accessoryLinearCapacity
            )
        }
        .padding()
        
    }
    private func startScan() {}
    private func pauseScan() {}
}

#Preview {
    ContentView().frame(minWidth: 500, minHeight: 300)
}
