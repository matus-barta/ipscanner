//
//  ScanConfiguration.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation

nonisolated struct ScanConfiguration: Sendable {
    let ports: [UInt16]
    let connectionTimeout: TimeInterval

    let maxConcurrentHosts: Int
    let maxConcurrentPortsPerHost: Int

    let reverseDNSEnabled: Bool
    let netBIOSEnabled: Bool
    let bonjourEnabled: Bool
}
