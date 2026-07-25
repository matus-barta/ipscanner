//
//  DeviceSearch.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//
import Foundation

nonisolated enum DeviceSearch {
    static func matches(
        _ device: Device,
        query: String
    ) -> Bool {
        let normalizedQuery = query
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedQuery.isEmpty else {
            return true
        }

        let serviceNames = device.openPorts
            .compactMap { PortDatabase.name(for: $0) }
            .joined(separator: " ")

        let searchableValues = [
            device.hostname ?? "",
            device.ip,
            device.mac ?? "",
            device.manufacturer ?? "",
            device.hostnameSource?.displayName ?? "",
            device.openPortsDisplay,
            serviceNames,
        ]

        return searchableValues.contains {
            $0.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }
}
