//
//  DeviceActions.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation

#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

@MainActor
enum DeviceActions {
    static func copy(
        _ value: String
    ) {
        #if os(macOS)
            let pasteboard = NSPasteboard.general

            pasteboard.clearContents()
            pasteboard.setString(
                value,
                forType: .string
            )
        #elseif os(iOS)
            UIPasteboard.general.string = value
        #endif
    }

    static func copyHostname(
        for device: Device
    ) {
        guard let hostname = device.hostname,
              !hostname.isEmpty
        else {
            return
        }

        copy(hostname)
    }

    static func copyIPAddress(
        for device: Device
    ) {
        copy(device.ip)
    }

    static func copyMACAddress(
        for device: Device
    ) {
        guard let mac = device.mac,
              !mac.isEmpty
        else {
            return
        }

        copy(mac)
    }

    static func copyManufacturer(
        for device: Device
    ) {
        guard let manufacturer = device.manufacturer,
              !manufacturer.isEmpty
        else {
            return
        }

        copy(manufacturer)
    }

    static func openWebInterface(
        for device: Device
    ) {
        guard let url = webURL(
            for: device
        ) else {
            return
        }

        open(url)
    }

    static func openSSH(
        for device: Device
    ) {
        guard device.openPorts.contains(22),
              let url = URL(
                  string: "ssh://\(device.ip)"
              )
        else {
            return
        }

        open(url)
    }

    static func openScreenSharing(
        for device: Device
    ) {
        guard device.openPorts.contains(5900),
              let url = URL(
                  string: "vnc://\(device.ip)"
              )
        else {
            return
        }

        open(url)
    }

    private static func webURL(
        for device: Device
    ) -> URL? {
        let scheme: String
        let port: UInt16?

        if device.openPorts.contains(443) {
            scheme = "https"
            port = nil
        } else if device.openPorts.contains(80) {
            scheme = "http"
            port = nil
        } else if device.openPorts.contains(8443) {
            scheme = "https"
            port = 8443
        } else if device.openPorts.contains(8006) {
            scheme = "https"
            port = 8006
        } else if device.openPorts.contains(8080) {
            scheme = "http"
            port = 8080
        } else if device.openPorts.contains(8000) {
            scheme = "http"
            port = 8000
        } else if device.openPorts.contains(8081) {
            scheme = "http"
            port = 8081
        } else {
            return nil
        }

        var components = URLComponents()

        components.scheme = scheme
        components.host = device.ip
        components.port = port.map(Int.init)

        return components.url
    }

    private static func open(
        _ url: URL
    ) {
        #if os(macOS)
            NSWorkspace.shared.open(url)
        #elseif os(iOS)
            UIApplication.shared.open(url)
        #endif
    }
}
