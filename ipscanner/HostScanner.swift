//
//  HostScanner.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

nonisolated struct HostScanResult: Sendable {
    let host: String
    let responded: Bool
    let openPorts: Set<UInt16>
    let checkedPorts: UInt16

    let hostname: String?
    let mac: String?
}

nonisolated enum HostScanner {
    static func scan(
        host: String,
        ports: [UInt16],
        timeout: TimeInterval
    ) async -> HostScanResult {
        var responded = false
        var openPorts = Set<UInt16>()
        var checkedPorts:UInt16 = 0

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
                // print("\(host):\(port) timeout")

            case .cancelled:
                print("\(host):\(port) cancelled")

                return HostScanResult(
                    host: host,
                    responded: responded,
                    openPorts: openPorts,
                    checkedPorts: checkedPorts,
                    hostname: nil,
                    mac: nil
                )

            case let .failed(error):
                checkedPorts += 1
                print("\(host):\(port) failed: \(error)")
            }
        }

        let mac = ArpResolver.macAddress(for: host)
        if let mac {
            // responded = true
            print("\(host) ARP -> \(mac)")
        }

        let reverseHostname = responded
            ? ReverseDNSResolver.hostname(for: host)
            : nil

        if let reverseHostname {
            print("\(host) reverse DNS -> \(reverseHostname)")
        }

        let netBIOSHostname = responded && reverseHostname == nil
            ? await NetBIOSResolver.hostname(for: host, timeout: 2.0)
            : nil

        if let netBIOSHostname {
            print("\(host) NetBIOS -> \(netBIOSHostname)")
        }

        let bonjourHostname = responded &&
            netBIOSHostname == nil &&
            reverseHostname == nil
            ? await MainActor.run {
                BonjourResolver.shared.hostname(for: host)
            }
            : nil

        let hostname = reverseHostname ?? netBIOSHostname ?? bonjourHostname

        return HostScanResult(
            host: host,
            responded: responded,
            openPorts: openPorts,
            checkedPorts: checkedPorts,
            hostname: hostname,
            mac: mac
        )
    }
}
