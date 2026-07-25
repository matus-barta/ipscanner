//
//  ContentView.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(Scanner.self) private var scanner
    @Environment(AppState.self) private var appState

    @AppStorage(
        AppPreferenceKeys.automaticallyShowInspector
    )
    private var automaticallyShowInspector =
        AppPreferenceDefaults.automaticallyShowInspector

    @State private var sortOrder: [KeyPathComparator<Device>] = [.init(\.ip, order: SortOrder.forward)]

    @FocusState private var subnetFieldFocused: Bool

    private var selectedDevice: Device? {
        scanner.devices.first {
            $0.id == appState.selectedDeviceID
        }
    }

    private var filteredDevices: [Device] {
        scanner.devices.filter {
            DeviceSearch.matches(
                $0,
                query: appState.searchText
            )
        }
    }

    var body: some View {
        @Bindable var appState = appState

        VStack(spacing: 10) {
            SubnetEditorView(subnetFieldFocused: $subnetFieldFocused)
            #if os(iOS)
                ScanStatusView()
            Divider()
            #endif
            DeviceTableView(
                selection: $appState.selectedDeviceID,
                sortOrder: $sortOrder,
                devices: filteredDevices
            )
            .onChange(of: sortOrder) {
                scanner.devices.sort(using: sortOrder)
            }
            .onChange(of: appState.selectedDeviceID) { _, newSelection in
                guard automaticallyShowInspector,
                      newSelection != nil
                else {
                    return
                }

                appState.inspectorPresented = true
            }
            .onChange(of: filteredDevices.map(\.id)) { _, visibleIDs in
                guard let selectedDeviceID = appState.selectedDeviceID else { return
                }
                if !visibleIDs.contains(selectedDeviceID) {
                    appState.selectedDeviceID = nil
                }
            }
            .searchable(
                text: $appState.searchText,
                isPresented: $appState.searchPresented,
                placement: .toolbar,
                prompt: "Search Devices"
            )
            #if os(macOS)
                ScanStatusView()
            #endif
        }
        .padding()
        .toolbar {
            ScannerToolbar(inspectorPresented: $appState.inspectorPresented)
        }
        .inspector(isPresented: $appState.inspectorPresented) {
            DeviceInspectorView(device: selectedDevice)
                .inspectorColumnWidth(min: 280, ideal: 340, max: 470)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                subnetFieldFocused = false
                #if os(macOS)
                    NSApp.keyWindow?.makeFirstResponder(nil)
                #endif
            }
        }
    }
}

#Preview {
    ContentView().frame(minWidth: 900, minHeight: 500)
        .environment(Scanner())
        .environment(AppState())
}
