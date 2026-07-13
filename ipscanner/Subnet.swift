//
//  Subnet.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

struct Subnet: Hashable {
    let network: String
    let prefix: Int

    var displayValue: String {
        "\(network)/\(prefix)"
    }

    static func parse(_ value: String) -> Subnet? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        let components = trimmed.split(separator: "/")

        guard components.count == 2 else {
            print("Invalid subnet format: \(value)")
            return nil
        }

        let ip = String(components[0])
        let prefixValue = String(components[1])

        guard isValidIPv4(ip) else {
            print("Invalid IPv4 address: \(ip)")
            return nil
        }

        guard let prefix = Int(prefixValue),
              (0 ... 32).contains(prefix)
        else {
            print("Invalid prefix: \(prefixValue)")
            return nil
        }

        guard let normalizedNetwork = normalizedNetworkAddress(
            ip,
            prefix: prefix
        ) else {
            print("Could not normalize subnet: \(value)")
            return nil
        }

        if normalizedNetwork != ip {
            print("Normalized \(ip)/\(prefix) -> \(normalizedNetwork)/\(prefix)")
        }

        return Subnet(
            network: normalizedNetwork,
            prefix: prefix
        )
    }

    func hosts() -> [String] {
        guard let networkInt = Self.ipv4ToUInt32(network) else {
            return []
        }

        guard (0 ... 32).contains(prefix) else {
            return []
        }

        let hostBits = 32 - prefix

        // Limit subnet size for now, to avoid freezing the app on huge ranges
        guard hostBits <= 16 else {
            print("Subnet too large: \(network)/\(prefix)")
            return []
        }

        let hostCount = UInt32(1) << UInt32(hostBits)

        let mask = Self.mask(forPrefix: prefix)
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

    private static func normalizedNetworkAddress(
        _ ip: String,
        prefix: Int
    ) -> String? {
        guard let ipInt = ipv4ToUInt32(ip) else {
            return nil
        }

        let mask = mask(forPrefix: prefix)
        let networkInt = ipInt & mask

        return uint32ToIPv4(networkInt)
    }

    static func isValidIPv4(_ ip: String) -> Bool {
        let components = ip.split(separator: ".")

        guard components.count == 4 else {
            return false
        }

        for component in components {
            guard let octet = UInt8(component) else {
                return false
            }

            // Reject values like "001" if you want strict IPv4 formatting
            if String(octet) != String(component) {
                return false
            }
        }

        return true
    }

    private static func mask(forPrefix prefix: Int) -> UInt32 {
        let hostBits = 32 - prefix

        if prefix == 0 {
            return 0
        }

        return UInt32.max << UInt32(hostBits)
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
        let o1 = (value >> 24) & 0xFF
        let o2 = (value >> 16) & 0xFF
        let o3 = (value >> 8) & 0xFF
        let o4 = value & 0xFF

        return "\(o1).\(o2).\(o3).\(o4)"
    }
}
