//
//  Device.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import Foundation

/// https://stackoverflow.com/questions/79666709/swiftdata-predicate-in-swift-6-language-mode
nonisolated struct Device: Identifiable, Hashable {
    let id = UUID()

    let ip: String

    var hostname: String?
    var hostnameSource: HostnameSource?

    var mac: String?
    var manufacturer: String?

    var openPorts: Set<UInt16> = []

    var hostnameSort: String {
        hostname ?? ""
    }

    var macSort: String {
        mac ?? ""
    }

    var manufacturerSort: String {
        manufacturer ?? ""
    }

    var openPortsDisplay: String {
        openPorts
            .sorted()
            .map(String.init)
            .joined(separator: ", ")
    }

    var ipSortable: UInt32 {
        let parts = ip
            .split(separator: ".")
            .compactMap { UInt32(String($0)) }

        guard parts.count == 4 else {
            return 0
        }

        return (parts[0] << 24)
            | (parts[1] << 16)
            | (parts[2] << 8)
            | parts[3]
    }
}
