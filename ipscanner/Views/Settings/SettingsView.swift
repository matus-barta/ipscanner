//
//  SettingsView.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(
        AppPreferenceKeys.defaultScanProfile
    )
    private var defaultScanProfile =
        AppPreferenceDefaults.scanProfile.rawValue

    @AppStorage(
        AppPreferenceKeys.connectionTimeout
    )
    private var connectionTimeout =
        AppPreferenceDefaults.connectionTimeout

    @AppStorage(
        AppPreferenceKeys.physicalInterfacesOnly
    )
    private var physicalInterfacesOnly =
        AppPreferenceDefaults.physicalInterfacesOnly

    @AppStorage(
        AppPreferenceKeys.automaticallyShowInspector
    )
    private var automaticallyShowInspector =
        AppPreferenceDefaults.automaticallyShowInspector

    @AppStorage(
        AppPreferenceKeys.reverseDNSEnabled
    )
    private var reverseDNSEnabled =
        AppPreferenceDefaults.reverseDNSEnabled

    @AppStorage(
        AppPreferenceKeys.netBIOSEnabled
    )
    private var netBIOSEnabled =
        AppPreferenceDefaults.netBIOSEnabled

    @AppStorage(
        AppPreferenceKeys.bonjourEnabled
    )
    private var bonjourEnabled =
        AppPreferenceDefaults.bonjourEnabled

    var body: some View {
        TabView {
            Tab(
                "General",
                systemImage: "gear"
            ) {
                generalSettings
            }

            Tab(
                "Discovery",
                systemImage: "network"
            ) {
                discoverySettings
            }
        }
        .frame(
            minWidth: 480,
            idealWidth: 520,
            minHeight: 330,
            idealHeight: 380
        )
    }

    private var generalSettings: some View {
        Form {
            Section("Scanning") {
                Picker(
                    "Default scan profile",
                    selection: $defaultScanProfile
                ) {
                    ForEach(ScanProfile.allCases) { profile in
                        Text(
                            "\(profile.displayName) (\(profile.portCount) ports)"
                        )
                        .tag(profile.rawValue)
                    }
                }

                Picker(
                    "Connection timeout",
                    selection: $connectionTimeout
                ) {
                    Text("0.25 seconds").tag(0.25)
                    Text("0.5 seconds").tag(0.5)
                    Text("1 second").tag(1.0)
                    Text("2 seconds").tag(2.0)
                }
            }

            Section("Interfaces") {
                Toggle(
                    "Select physical interfaces automatically",
                    isOn: $physicalInterfacesOnly
                )

                Text(
                    "Automatically selects active Wi-Fi and Ethernet interfaces."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Inspector") {
                Toggle(
                    "Show inspector when selecting a device",
                    isOn: $automaticallyShowInspector
                )
            }
        }
        .formStyle(.grouped)
        .scenePadding()
    }

    private var discoverySettings: some View {
        Form {
            Section("Hostname Discovery") {
                Toggle(
                    "Reverse DNS",
                    isOn: $reverseDNSEnabled
                )

                Toggle(
                    "NetBIOS",
                    isOn: $netBIOSEnabled
                )

                Toggle(
                    "Bonjour / mDNS",
                    isOn: $bonjourEnabled
                )
            }

            Section {
                Text(
                    "Hostname sources are tried in this order: Reverse DNS, NetBIOS, then Bonjour."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Reset") {
                Button("Restore Default Settings") {
                    restoreDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .scenePadding()
    }

    private func restoreDefaults() {
        defaultScanProfile =
            AppPreferenceDefaults.scanProfile.rawValue

        connectionTimeout =
            AppPreferenceDefaults.connectionTimeout

        physicalInterfacesOnly =
            AppPreferenceDefaults.physicalInterfacesOnly

        automaticallyShowInspector =
            AppPreferenceDefaults.automaticallyShowInspector

        reverseDNSEnabled =
            AppPreferenceDefaults.reverseDNSEnabled

        netBIOSEnabled =
            AppPreferenceDefaults.netBIOSEnabled

        bonjourEnabled =
            AppPreferenceDefaults.bonjourEnabled
    }
}

#Preview {
    SettingsView()
}
