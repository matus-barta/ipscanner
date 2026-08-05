//
//  Scanner+Preferences.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation

@MainActor
extension Scanner {
    func reloadDiscoveryPreferences() {
        let preferences = ScannerPreferences.load()

        applyRuntimePreferences(preferences)

        if preferences.physicalInterfacesOnly
            != interfaceSelection.physicalInterfacesOnly
        {
            interfaceSelection.setPhysicalInterfacesOnly(
                preferences.physicalInterfacesOnly
            )
        }

        if bonjourEnabled {
            BonjourResolver.shared.start()
        }
    }

    func makeScanConfiguration() -> ScanConfiguration {
        ScanConfiguration(
            ports: scanProfile.ports,
            connectionTimeout: connectionTimeout,
            maxConcurrentHosts: maxConcurrentHosts,
            maxConcurrentPortsPerHost: maxConcurrentPortsPerHost,
            reverseDNSEnabled: reverseDNSEnabled,
            netBIOSEnabled: netBIOSEnabled,
            bonjourEnabled: bonjourEnabled
        )
    }
}
