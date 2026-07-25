//
//  NetworkInterfaceType.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//

import Foundation

nonisolated enum NetworkInterfaceType: String, Hashable, Sendable {
    case wifi
    case ethernet
    case vpn
    case bridge
    case cellular
    case bluetooth
    case loopback
    case tunnel
    case other

    var displayName: String {
        switch self {
        case .wifi:
            "Wi-Fi"

        case .ethernet:
            "Ethernet"

        case .vpn:
            "VPN"

        case .bridge:
            "Bridge"

        case .cellular:
            "Cellular"

        case .bluetooth:
            "Bluetooth"

        case .loopback:
            "Loopback"

        case .tunnel:
            "Tunnel"

        case .other:
            "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .wifi:
            "wifi"

        case .ethernet:
            "cable.connector"

        case .vpn:
            "lock.shield"

        case .bridge:
            "point.3.connected.trianglepath.dotted"

        case .cellular:
            "antenna.radiowaves.left.and.right"

        case .bluetooth:
            "wave.3.right"

        case .loopback:
            "arrow.trianglehead.2.clockwise.rotate.90"

        case .tunnel:
            "arrow.left.arrow.right"

        case .other:
            "network"
        }
    }

    var isPhysical: Bool {
        switch self {
        case .wifi, .ethernet, .cellular:
            true

        default:
            false
        }
    }
}
