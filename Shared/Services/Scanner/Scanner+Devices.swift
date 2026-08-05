//
//  Scanner+Devices.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation

@MainActor
extension Scanner {
    func device(
        withID id: Device.ID?
    ) -> Device? {
        guard let id else {
            return nil
        }

        return devices.first {
            $0.id == id
        }
    }

    func removeDevice(
        id: Device.ID
    ) {
        devices.removeAll {
            $0.id == id
        }
    }

    func configureBonjourResolver() {
        BonjourResolver.shared.onHostnameFound = {
            [weak self] ip, hostname in
            self?.applyBonjourHostname(
                ip: ip,
                hostname: hostname
            )
        }
    }

    func makeDevice(
        from result: HostScanResult
    ) -> Device {
        Device(
            ip: result.host,
            hostname: result.hostname,
            hostnameSource: result.hostnameSource,
            mac: result.mac,
            manufacturer: MacVendorResolver.vendor(
                for: result.mac
            ),
            openPorts: result.openPorts
        )
    }

    func insertDevice(
        _ device: Device
    ) {
        let insertionIndex = devices.firstIndex {
            $0.ipSortable > device.ipSortable
        } ?? devices.endIndex

        devices.insert(
            device,
            at: insertionIndex
        )
    }

    func applyBonjourHostname(
        ip: String,
        hostname: String
    ) {
        guard bonjourEnabled else {
            return
        }

        guard let index = devices.firstIndex(
            where: {
                $0.ip == ip
            }
        ) else {
            return
        }

        guard devices[index].hostname?.isEmpty
            != false
        else {
            return
        }

        devices[index].hostname = hostname
        devices[index].hostnameSource = .bonjour
    }
}
