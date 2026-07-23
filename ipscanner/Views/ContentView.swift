//
//  ContentView.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var inspectorPresented = false
    @Environment(Scanner.self) private var scanner

    @State private var sortOrder: [KeyPathComparator<Device>] = [.init(\.ip, order: SortOrder.forward)]

    @State private var selection: Device.ID? = nil // Set<Device.ID> = [] - multiple

    private var selectedDevice: Device? {
        scanner.devices.first {
            $0.id == selection
        }
    }

    @State private var search = ""

    @FocusState private var subnetFieldFocused: Bool

    var body: some View {
        VStack(spacing: 10) {
            SubnetEditorView(subnetFieldFocused: $subnetFieldFocused)

            DeviceTableView(
                selection: $selection,
                sortOrder: $sortOrder,
                devices: scanner.devices
            )
            .onChange(of: sortOrder) {
                scanner.devices.sort(using: sortOrder)
            }
            .onChange(of: selection) { _, newSelection in
                inspectorPresented = newSelection != nil
            }
            .searchable(text: $search)

            ScanStatusView()
        }
        .padding()
        .toolbar {
            ScannerToolbar(inspectorPresented: $inspectorPresented)
        }
        .inspector(isPresented: $inspectorPresented) {
            DeviceInspectorView(device: selectedDevice)
                .inspectorColumnWidth(min: 260, ideal: 320, max: 450)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                subnetFieldFocused = false
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }
}

#Preview {
    ContentView().frame(minWidth: 900, minHeight: 500)
        .environment(Scanner())
}
