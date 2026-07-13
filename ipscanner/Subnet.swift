//
//  Subnet.swift
//  ipscanner
//
//  Created by Matus Barta on 13/07/2026.
//

import Foundation

struct Subnet: Hashable {
    let network: String
    let prefix: Int

    func hosts() -> [String] {
        guard let networkInt = Self.ipv4ToUInt32(network) else {
            return []
        }

        guard (0 ... 32).contains(prefix) else {
            return []
        }

        let hostBits = 32 - prefix

        // Limit subnet size for now
        guard hostBits <= 16 else {
            print("Subnet too large: \(network)/\(prefix)")
            return []
        }

        let hostCount = UInt32(1) << UInt32(hostBits)

        let mask: UInt32 = prefix == 0
            ? 0
            : UInt32.max << UInt32(hostBits)

        let baseNetwork = networkInt & mask

        if prefix == 32 {
            return [Self.uint32ToIPv4(baseNetwork)]
        }

        if prefix == 31 {
            return [
                Self.uint32ToIPv4(baseNetwork),
                Self.uint32ToIPv4(baseNetwork + 1),
            ]
        }

        return (1 ..< hostCount - 1).map { offset in
            Self.uint32ToIPv4(baseNetwork + offset)
        }
    }

    private static func ipv4ToUInt32(_ ip: String) -> UInt32? {
        let components = ip.split(separator: ".")

        guard components.count == 4 else {
            return nil
        }

        var value: UInt32 = 0

        for component in components {
            guard let octet = UInt8(component) else {
                return nil
            }

            value = (value << 8) | UInt32(octet)
        }

        return value
    }

    private static func uint32ToIPv4(_ value: UInt32) -> String {
        let o1 = (value >> 24) & 0xff
        let o2 = (value >> 16) & 0xff
        let o3 = (value >> 8) & 0xff
        let o4 = value & 0xff

        return "\(o1).\(o2).\(o3).\(o4)"
    }
}