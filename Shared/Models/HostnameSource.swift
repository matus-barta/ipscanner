//
//  HostnameSource.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation

nonisolated enum HostnameSource: String, Hashable, Sendable {
    case reverseDNS
    case netBIOS
    case bonjour

    var displayName: String {
        switch self {
        case .reverseDNS:
            "Reverse DNS"

        case .netBIOS:
            "NetBIOS"

        case .bonjour:
            "Bonjour / mDNS"
        }
    }

    var systemImage: String {
        switch self {
        case .reverseDNS:
            "network"

        case .netBIOS:
            "desktopcomputer"

        case .bonjour:
            "dot.radiowaves.left.and.right"
        }
    }
}
