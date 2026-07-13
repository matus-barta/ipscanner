//
//  Scanner.swift
//  ipscanner
//
//  Created by Matus Barta on 11/07/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class Scanner {
    var devices: [Device] = []
    var progress: Double = 0.0
    var isScanning = false

    var subnets: String = ""

    var subnetList: [Subnet] = []

    private var scanTask: Task<Void, Never>?

    private let defaultPorts = [
        22,
        80,
        443,
        445,
        3389,
    ]

    init() {
        refreshSubnets()
    }

    func startScan() {
        guard !isScanning else {
            return
        }

        print("Scanner.startScan()")

        normalizeSubnetInput()

        devices.removeAll()
        progress = 0
        isScanning = true

        scanTask = Task {
            await scanSubnets()
        }
    }

    func pauseScan() {
        print("Scanner.pauseScan()")
    }

    func stopScan() {
        print("Scanner.stopScan()")

        scanTask?.cancel()
        scanTask = nil

        isScanning = false
    }

    func refreshSubnets() {
        let interfaces = NetworkInterfaces.getAll()

        subnetList = interfaces
            .filter(\.isPhysical)
            .compactMap { interface in
                guard let network = interface.networkAddress else {
                    return nil
                }

                return Subnet(
                    network: network,
                    prefix: interface.cidrPrefix
                )
            }

        subnetList = Array(Set(subnetList)).sorted {
            "\($0.network)/\($0.prefix)" < "\($1.network)/\($1.prefix)"
        }

        subnets = subnetList
            .map { "\($0.network)/\($0.prefix)" }
            .joined(separator: ", ")
    }

    func parseSubnets() {
        subnetList = subnets
            .split(separator: ",")
            .compactMap { part in
                Subnet.parse(String(part))
            }

        print("=== Parsed subnets ===")

        for subnet in subnetList {
            print("\(subnet.network)/\(subnet.prefix)")
        }

        print("Total: \(subnetList.count)")
    }

    func normalizeSubnetInput() {
        parseSubnets()

        let normalized = Array(Set(subnetList))
            .sorted {
                $0.displayValue < $1.displayValue
            }

        subnetList = normalized

        subnets = normalized
            .map(\.displayValue)
            .joined(separator: ", ")

        print("=== Normalized subnet input ===")
        print(subnets)
    }

    private func scanSubnets() async {
        defer {
            isScanning = false
            scanTask = nil
        }

        let hosts = subnetList.flatMap {
            $0.hosts()
        }

        let ports = defaultPorts
        let totalChecks = hosts.count * ports.count

        guard totalChecks > 0 else {
            isScanning = false
            progress = 0
            return
        }

        var completedChecks = 0

        for host in hosts {
            if Task.isCancelled {
                break
            }

            var hostResponded = false
            var openPorts = Set<Int>()

            for port in ports {
                if Task.isCancelled {
                    break
                }

                let result = await PortScanner.scan(
                    host: host,
                    port: port,
                    timeout: 1.0
                )

                if Task.isCancelled {
                    break
                }

                completedChecks += 1
                progress = Double(completedChecks) / Double(totalChecks)

                switch result.state {
                case .open:
                    hostResponded = true
                    openPorts.insert(port)
                    print("\(host):\(port) open")

                case .closed:
                    hostResponded = true
                    print("\(host):\(port) closed, but host is alive")

                case .timeout:
                    print("\(host):\(port) timeout")

                case .cancelled:
                    print("\(host):\(port) cancelled")
                    return

                case let .failed(error):
                    print("\(host):\(port) failed: \(error)")
                }
            }

            if hostResponded {
                devices.append(
                    Device(
                        ip: host,
                        hostname: nil,
                        mac: nil,
                        manufacturer: nil,
                        openPorts: openPorts
                    )
                )
            }
        }
        
        progress = 1.0
    }
}
