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

    init() {
        refreshSubnets()
    }

    func refreshSubnets() {
        let interfaces = NetworkInterfaces.getAll()

        let discoveredSubnets = interfaces
            .filter(\.isPhysical)
            .compactMap(\.subnet)

        subnets = discoveredSubnets.joined(separator: ", ")
    }

    func startScan() {
        print("Scanner.startScan()")

        devices.append(
            Device(
                ip: "192.168.1.10",
                hostname: "test",
                mac: nil,
                manufacturer: nil
            )
        )
    }

    func pauseScan() {
        print("Scanner.pauseScan()")
    }

    func stopScan() {
        print("Scanner.stopScan()")
    }
}
