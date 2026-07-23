//
//  AppPreferenceKeys.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
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
}

nonisolated enum AppPreferenceDefaults {
    static let scanProfile: ScanProfile = .quick
    static let connectionTimeout: Double = 0.5

    static let physicalInterfacesOnly = true
    static let automaticallyShowInspector = true

    static let reverseDNSEnabled = true
    static let netBIOSEnabled = true
    static let bonjourEnabled = true
}
