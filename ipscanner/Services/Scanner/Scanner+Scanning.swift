//
//  Scanner+Scanning.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//
import Foundation

@MainActor
extension Scanner {
    func runScan(
        hosts: [String],
        configuration: ScanConfiguration
    ) async {
        defer {
            isScanning = false
            scanTask = nil
        }

        await withTaskGroup(
            of: HostScanResult.self
        ) { group in
            let initialCount = min(
                configuration.maxConcurrentHosts,
                hosts.count
            )

            for index in 0 ..< initialCount {
                addHostTask(
                    host: hosts[index],
                    configuration: configuration,
                    to: &group
                )
            }

            var nextIndex = initialCount

            while let result = await group.next() {
                if Task.isCancelled {
                    group.cancelAll()
                    return
                }

                processScanResult(result)

                if nextIndex < hosts.count {
                    addHostTask(
                        host: hosts[nextIndex],
                        configuration: configuration,
                        to: &group
                    )

                    nextIndex += 1
                }
            }
        }

        if !Task.isCancelled {
            progress = 1.0
        }
    }

    private func addHostTask(
        host: String,
        configuration: ScanConfiguration,
        to group: inout TaskGroup<HostScanResult>
    ) {
        group.addTask {
            await HostScanner.scan(
                host: host,
                ports: configuration.ports,
                timeout: configuration.connectionTimeout,
                maxConcurrentPorts:
                configuration.maxConcurrentPortsPerHost,
                reverseDNSEnabled:
                configuration.reverseDNSEnabled,
                netBIOSEnabled:
                configuration.netBIOSEnabled,
                bonjourEnabled:
                configuration.bonjourEnabled
            )
        }
    }

    private func processScanResult(
        _ result: HostScanResult
    ) {
        scannedHosts += 1

        if result.responded {
            onlineHosts += 1
            insertDevice(
                makeDevice(from: result)
            )
        }

        guard totalHosts > 0 else {
            progress = 0
            return
        }

        progress = Double(scannedHosts)
            / Double(totalHosts)
    }

    func resetForNewScan(
        totalHosts: Int
    ) {
        devices.removeAll()

        self.totalHosts = totalHosts
        scannedHosts = 0
        onlineHosts = 0
        progress = 0
    }

    func resetProgress() {
        progress = 0
        totalHosts = 0
        scannedHosts = 0
        onlineHosts = 0
    }
}
