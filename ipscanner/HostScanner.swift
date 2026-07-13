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
        timeout: TimeInterval,
        maxConcurrentPorts: Int = 8
    ) async -> HostScanResult {
        var responded = false
        var openPorts = Set<UInt16>()
        var checkedPorts: UInt16 = 0

        await withTaskGroup(of: PortScanResult.self) { group in
            let initialCount = min(maxConcurrentPorts, ports.count)

            for index in 0 ..< initialCount {
                let port = ports[index]

                group.addTask {
                    await PortScanner.scan(
                        host: host,
                        port: port,
                        timeout: timeout
                    )
                }
            }

            var nextIndex = initialCount

            while let result = await group.next() {
                if Task.isCancelled {
                    group.cancelAll()
                    return
                }

                switch result.state {
                case .open:
                    responded = true
                    openPorts.insert(result.port)
                    checkedPorts += 1
                    print("\(host):\(result.port) open")

                case .closed:
                    responded = true
                    checkedPorts += 1
                    print("\(host):\(result.port) closed, but host is alive")

                case .timeout:
                    checkedPorts += 1
                    // print("\(host):\(result.port) timeout")

                case .cancelled:
                    print("\(host):\(result.port) cancelled")
                    group.cancelAll()
                    return

                case let .failed(error):
                    checkedPorts += 1
                    print("\(host):\(result.port) failed: \(error)")
                }

                if nextIndex < ports.count {
                    let port = ports[nextIndex]
                    nextIndex += 1

                    group.addTask {
                        await PortScanner.scan(
                            host: host,
                            port: port,
                            timeout: timeout
                        )
                    }
                }
            }
        }

        if Task.isCancelled {
            return HostScanResult(
                host: host,
                responded: responded,
                openPorts: openPorts,
                checkedPorts: checkedPorts,
                hostname: nil,
                mac: nil
            )
        }

        let mac = ArpResolver.macAddress(for: host)

        if let mac {
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
