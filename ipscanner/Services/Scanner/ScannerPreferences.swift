//
//  ScannerPreferences.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//
import Foundation

nonisolated struct ScannerPreferences: Sendable {
    let defaultScanProfile: ScanProfile
    let connectionTimeout: TimeInterval

    let physicalInterfacesOnly: Bool

    let reverseDNSEnabled: Bool
    let netBIOSEnabled: Bool
    let bonjourEnabled: Bool

    static func load(
        from defaults: UserDefaults = .standard
    ) -> ScannerPreferences {
        ScannerPreferences(
            defaultScanProfile: loadScanProfile(
                from: defaults
            ),
            connectionTimeout: loadDouble(
                key: AppPreferenceKeys.connectionTimeout,
                defaultValue: AppPreferenceDefaults.connectionTimeout,
                from: defaults
            ),
            physicalInterfacesOnly: loadBool(
                key: AppPreferenceKeys.physicalInterfacesOnly,
                defaultValue: AppPreferenceDefaults.physicalInterfacesOnly,
                from: defaults
            ),
            reverseDNSEnabled: loadBool(
                key: AppPreferenceKeys.reverseDNSEnabled,
                defaultValue: AppPreferenceDefaults.reverseDNSEnabled,
                from: defaults
            ),
            netBIOSEnabled: loadBool(
                key: AppPreferenceKeys.netBIOSEnabled,
                defaultValue: AppPreferenceDefaults.netBIOSEnabled,
                from: defaults
            ),
            bonjourEnabled: loadBool(
                key: AppPreferenceKeys.bonjourEnabled,
                defaultValue: AppPreferenceDefaults.bonjourEnabled,
                from: defaults
            )
        )
    }

    private static func loadScanProfile(
        from defaults: UserDefaults
    ) -> ScanProfile {
        guard let rawValue = defaults.string(
            forKey: AppPreferenceKeys.defaultScanProfile
        ) else {
            return AppPreferenceDefaults.scanProfile
        }

        return ScanProfile(rawValue: rawValue)
            ?? AppPreferenceDefaults.scanProfile
    }

    private static func loadBool(
        key: String,
        defaultValue: Bool,
        from defaults: UserDefaults
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return defaults.bool(forKey: key)
    }

    private static func loadDouble(
        key: String,
        defaultValue: Double,
        from defaults: UserDefaults
    ) -> Double {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return defaults.double(forKey: key)
    }
}
