//
//  AppPreferenceKeys.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation

nonisolated enum AppPreferenceKeys {
    static let defaultScanProfile = "defaultScanProfile"
    static let connectionTimeout = "connectionTimeout"
    static let physicalInterfacesOnly = "physicalInterfacesOnly"
    static let automaticallyShowInspector = "automaticallyShowInspector"

    static let reverseDNSEnabled = "reverseDNSEnabled"
    static let netBIOSEnabled = "netBIOSEnabled"
    static let bonjourEnabled = "bonjourEnabled"

    static let maxConcurrentHosts = "maxConcurrentHosts"
    static let maxConcurrentPortsPerHost = "maxConcurrentPortsPerHost"
}

nonisolated enum AppPreferenceDefaults {
    static let scanProfile: ScanProfile = .quick
    static let connectionTimeout: Double = 0.5

    static let physicalInterfacesOnly = true
    static let automaticallyShowInspector = true

    static let reverseDNSEnabled = true
    static let netBIOSEnabled = true
    static let bonjourEnabled = true

    #if os(macOS)
        static let maxConcurrentHosts = 64
        static let maxConcurrentPortsPerHost = 8
    #else
        static let maxConcurrentHosts = 24
        static let maxConcurrentPortsPerHost = 4
    #endif
}
