//
//  SettingsView.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
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

    @AppStorage(
        AppPreferenceKeys.maxConcurrentHosts
    )

    private var maxConcurrentHosts =
        AppPreferenceDefaults.maxConcurrentHosts

    @AppStorage(
        AppPreferenceKeys.maxConcurrentPortsPerHost
    )
    private var maxConcurrentPortsPerHost =
        AppPreferenceDefaults.maxConcurrentPortsPerHost

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
            Tab(
                "Advanced",
                systemImage: "slider.horizontal.3"
            ) {
                advancedSettings
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

    private var advancedSettings: some View {
        Form {
            Section("Concurrency") {
                Stepper(
                    value: $maxConcurrentHosts,
                    in: 1 ... 128,
                    step: 8
                ) {
                    LabeledContent(
                        "Concurrent hosts",
                        value: "\(maxConcurrentHosts)"
                    )
                }

                Stepper(
                    value: $maxConcurrentPortsPerHost,
                    in: 1 ... 32
                ) {
                    LabeledContent(
                        "Ports per host",
                        value: "\(maxConcurrentPortsPerHost)"
                    )
                }
            }

            Section {
                LabeledContent(
                    "Maximum simultaneous attempts",
                    value: "\(maximumSimultaneousAttempts)"
                )

                Text(
                    "Higher values may complete scans faster, but increase CPU, memory, network load, and battery usage."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Section("Recommended Defaults") {
                Button("Use Recommended Values") {
                    restoreConcurrencyDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .scenePadding()
    }

    private var maximumSimultaneousAttempts: Int {
        maxConcurrentHosts
            * maxConcurrentPortsPerHost
    }

    private func restoreConcurrencyDefaults() {
        maxConcurrentHosts =
            AppPreferenceDefaults.maxConcurrentHosts

        maxConcurrentPortsPerHost =
            AppPreferenceDefaults.maxConcurrentPortsPerHost
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

        restoreConcurrencyDefaults()
    }
}

#Preview {
    SettingsView()
}
