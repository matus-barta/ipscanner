//
//  ContentView.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import Network
import SwiftUI

struct ContentView: View {
    @State private var scanner = Scanner()

    @State private var sortOrder: [KeyPathComparator<Device>] = [.init(\.ip, order: SortOrder.forward)]

    @State private var selection: Device.ID? = nil // Set<Device.ID> = [] - multiple
    @State private var search = ""

    @FocusState private var subnetFieldFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                TextField("", text: $scanner.subnets)
                    .focused($subnetFieldFocused)
                Button("Scan for subnets", systemImage: "arrow.trianglehead.clockwise.rotate.90",
                       action: scanner.refreshSubnets)
                    .labelStyle(.iconOnly)
            }

            Table(of: Device.self, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Hostname", value: \.hostnameSort)
                TableColumn("IP address", value: \.ip)
                TableColumn("MAC address", value: \.macSort)
                TableColumn("Manufacturer", value: \.manufacturerSort)
            } rows: {
                ForEach(scanner.devices) { device in
                    TableRow(device)
                        .contextMenu {
                            Button("Stuff1") {}
                            Button("Stuff2") {}
                            Divider()
                            Button(role: .destructive) {} label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .onChange(of: sortOrder) {
                scanner.devices.sort(using: sortOrder)
            }
            .searchable(text: $search)
            .toolbar {
                ToolbarItem {
                    Button("Scan", systemImage: "play.fill", action: scanner.startScan)
                        .labelStyle(.titleAndIcon)
                        .buttonStyle(.glassProminent)
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
            }

            Gauge(value: scanner.progress, in: 0.0 ... 1.0) {
                Text("Scanning")
            } currentValueLabel: {
                Text("\(Int(scanner.progress * 100)) out of 100")
            }.gaugeStyle(
                .accessoryLinearCapacity
            )
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                subnetFieldFocused = false
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }
}

#Preview {
    ContentView().frame(minWidth: 500, minHeight: 300)
}
