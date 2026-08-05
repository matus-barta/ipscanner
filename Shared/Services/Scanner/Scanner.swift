//
//  Scanner.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation
import Observation

@MainActor
@Observable
final class Scanner {
    // MARK: - Results

    var devices: [Device] = []

    // MARK: - Progress

    var progress = 0.0
    var isScanning = false

    var totalHosts = 0
    var scannedHosts = 0
    var onlineHosts = 0

    var offlineHosts: Int {
        max(0, scannedHosts - onlineHosts)
    }

    // MARK: - Network selection

    var subnets = ""
    var subnetList: [Subnet] = []

    let interfaceSelection = InterfaceSelection()

    // MARK: - Active scan configuration

    var scanProfile: ScanProfile
    var connectionTimeout: TimeInterval

    private(set) var reverseDNSEnabled: Bool
    private(set) var netBIOSEnabled: Bool
    private(set) var bonjourEnabled: Bool

    // MARK: - Runtime

    var scanTask: Task<Void, Never>?

    private(set) var maxConcurrentHosts: Int
    private(set) var maxConcurrentPortsPerHost: Int

    // MARK: - Initialization

    init() {
        let preferences = ScannerPreferences.load()

        scanProfile = preferences.defaultScanProfile
        connectionTimeout = preferences.connectionTimeout

        reverseDNSEnabled = preferences.reverseDNSEnabled
        netBIOSEnabled = preferences.netBIOSEnabled
        bonjourEnabled = preferences.bonjourEnabled

        maxConcurrentHosts = preferences.maxConcurrentHosts
        maxConcurrentPortsPerHost =
            preferences.maxConcurrentPortsPerHost

        configureInterfaceSelection(
            physicalOnly: preferences.physicalInterfacesOnly
        )

        configureBonjourResolver()

        if bonjourEnabled {
            BonjourResolver.shared.start()
        }
    }

    // MARK: - Public actions

    func startScan() {
        guard !isScanning else {
            return
        }

        reloadDiscoveryPreferences()
        normalizeSubnetInput()

        let hosts = uniqueHosts()

        resetForNewScan(totalHosts: hosts.count)

        guard !hosts.isEmpty else {
            return
        }

        isScanning = true

        let configuration = makeScanConfiguration()

        scanTask = Task {
            await runScan(
                hosts: hosts,
                configuration: configuration
            )
        }
    }

    func stopScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
    }

    func pauseScan() {
        print("Scanner.pauseScan()")
    }

    func clearResults() {
        guard !isScanning else {
            return
        }

        devices.removeAll()
        resetProgress()
    }

    func refreshInterfaces() {
        interfaceSelection.refresh()
    }

    func applyRuntimePreferences(
        _ preferences: ScannerPreferences
    ) {
        reverseDNSEnabled = preferences.reverseDNSEnabled
        netBIOSEnabled = preferences.netBIOSEnabled
        bonjourEnabled = preferences.bonjourEnabled

        maxConcurrentHosts = min(
            max(preferences.maxConcurrentHosts, 1),
            128
        )

        maxConcurrentPortsPerHost = min(
            max(preferences.maxConcurrentPortsPerHost, 1),
            32
        )
    }
}
