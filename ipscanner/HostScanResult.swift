//
//  HostScanResult.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

nonisolated struct HostScanResult: Sendable {
    let host: String
    let responded: Bool
    let openPorts: Set<Int>
    let checkedPorts: Int
}

nonisolated enum HostScanner {
    static func scan(
        host: String,
        ports: [Int],
        timeout: TimeInterval = 1.0
    ) async -> HostScanResult {
        var responded = false
        var openPorts = Set<Int>()
        var checkedPorts = 0

        for port in ports {
            if Task.isCancelled {
                break
            }

            let result = await PortScanner.scan(
                host: host,
                port: port,
                timeout: timeout
            )

            if Task.isCancelled {
                break
            }

            switch result.state {
            case .open:
                responded = true
                openPorts.insert(port)
                checkedPorts += 1
                print("\(host):\(port) open")

            case .closed:
                responded = true
                checkedPorts += 1
                print("\(host):\(port) closed, but host is alive")

            case .timeout:
                checkedPorts += 1
                print("\(host):\(port) timeout")

            case .cancelled:
                print("\(host):\(port) cancelled")
                return HostScanResult(
                    host: host,
                    responded: responded,
                    openPorts: openPorts,
                    checkedPorts: checkedPorts
                )

            case let .failed(error):
                checkedPorts += 1
                print("\(host):\(port) failed: \(error)")
            }
        }

        return HostScanResult(
            host: host,
            responded: responded,
            openPorts: openPorts,
            checkedPorts: checkedPorts
        )
    }
}
