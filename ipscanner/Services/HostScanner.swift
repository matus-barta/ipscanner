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
    private static let discoveryPorts: [UInt16] = [
        22, // SSH
        80, // HTTP
        443, // HTTPS
        445, // SMB
        3389, // RDP
        554, // RTSP
        631, // IPP
        8008, // Chromecast
        8009, // Chromecast
        9100, // JetDirect
    ]

    private static let postAlivePorts: [UInt16] = [
        53, // DNS
        5353, // mDNS, TCP check only for now
        1900, // SSDP, TCP check only for now
    ]

    static func scan(
        host: String,
        ports: [UInt16],
        timeout: TimeInterval,
        maxConcurrentPorts: Int = 8
    ) async -> HostScanResult {
        var responded = false
        var openPorts = Set<UInt16>()
        var checkedPorts: UInt16 = 0

        let requestedPorts = Array(Set(ports)).sorted()

        guard !requestedPorts.isEmpty else {
            return HostScanResult(
                host: host,
                responded: false,
                openPorts: [],
                checkedPorts: 0,
                hostname: nil,
                mac: nil
            )
        }

        // Stage 1: probe only discovery ports first.
        let discoverySet = Set(discoveryPorts)

        let probePorts = requestedPorts.filter {
            discoverySet.contains($0)
        }

        let effectiveProbePorts = probePorts.isEmpty
            ? Array(requestedPorts.prefix(min(5, requestedPorts.count)))
            : probePorts

        let probeResult = await scanPorts(
            host: host,
            ports: effectiveProbePorts,
            timeout: timeout,
            maxConcurrentPorts: maxConcurrentPorts
        )

        responded = probeResult.responded
        openPorts.formUnion(probeResult.openPorts)
        checkedPorts += probeResult.checkedPorts

        if probeResult.cancelled || Task.isCancelled {
            return HostScanResult(
                host: host,
                responded: responded,
                openPorts: openPorts,
                checkedPorts: checkedPorts,
                hostname: nil,
                mac: nil
            )
        }

        // Early fail:
        // If discovery ports all timed out/failed, do not scan full profile.
        guard responded else {
            return HostScanResult(
                host: host,
                responded: false,
                openPorts: [],
                checkedPorts: checkedPorts,
                hostname: nil,
                mac: nil
            )
        }

        // Stage 2: host is alive, scan remaining profile ports.
        let alreadyScanned = Set(effectiveProbePorts)

        let remainingPorts = requestedPorts.filter {
            !alreadyScanned.contains($0)
        }

        let fullResult = await scanPorts(
            host: host,
            ports: remainingPorts,
            timeout: timeout,
            maxConcurrentPorts: maxConcurrentPorts
        )

        responded = responded || fullResult.responded
        openPorts.formUnion(fullResult.openPorts)
        checkedPorts += fullResult.checkedPorts

        if fullResult.cancelled || Task.isCancelled {
            return HostScanResult(
                host: host,
                responded: responded,
                openPorts: openPorts,
                checkedPorts: checkedPorts,
                hostname: nil,
                mac: nil
            )
        }

        // Stage 3: scan ports that should never be used for discovery.
        // These run only after the host is already confirmed alive.
        let requestedPortSet = Set(requestedPorts)

        let postAlivePortsToScan = postAlivePorts.filter {
            !requestedPortSet.contains($0)
        }

        let postAliveResult = await scanPorts(
            host: host,
            ports: postAlivePortsToScan,
            timeout: timeout,
            maxConcurrentPorts: maxConcurrentPorts
        )

        openPorts.formUnion(postAliveResult.openPorts)
        checkedPorts += postAliveResult.checkedPorts

        if postAliveResult.cancelled || Task.isCancelled {
            return HostScanResult(
                host: host,
                responded: responded,
                openPorts: openPorts,
                checkedPorts: checkedPorts,
                hostname: nil,
                mac: nil
            )
        }

        // Enrichment
        let mac = ArpResolver.macAddress(for: host)

        if let mac {
            print("\(host) ARP -> \(mac)")
        }

        let reverseHostname = ReverseDNSResolver.hostname(for: host)

        if let reverseHostname {
            print("\(host) reverse DNS -> \(reverseHostname)")
        }

        let netBIOSHostname = reverseHostname == nil
            ? await NetBIOSResolver.hostname(for: host, timeout: 2.0)
            : nil

        if let netBIOSHostname {
            print("\(host) NetBIOS -> \(netBIOSHostname)")
        }

        let bonjourHostname = reverseHostname == nil && netBIOSHostname == nil
            ? await MainActor.run {
                BonjourResolver.shared.hostname(for: host)
            }
            : nil

        if let bonjourHostname {
            print("\(host) Bonjour -> \(bonjourHostname)")
        }

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

    private static func scanPorts(
        host: String,
        ports: [UInt16],
        timeout: TimeInterval,
        maxConcurrentPorts: Int
    ) async -> (
        responded: Bool,
        openPorts: Set<UInt16>,
        checkedPorts: UInt16,
        cancelled: Bool
    ) {
        guard !ports.isEmpty else {
            return (
                responded: false,
                openPorts: [],
                checkedPorts: 0,
                cancelled: false
            )
        }

        var responded = false
        var openPorts = Set<UInt16>()
        var checkedPorts: UInt16 = 0
        var cancelled = false

        let concurrency = max(1, maxConcurrentPorts)

        await withTaskGroup(of: PortScanResult.self) { group in
            let initialCount = min(concurrency, ports.count)

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
                    cancelled = true
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

                case .cancelled:
                    cancelled = true
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

        return (
            responded: responded,
            openPorts: openPorts,
            checkedPorts: checkedPorts,
            cancelled: cancelled
        )
    }
}
