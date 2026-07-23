//
//  NetworkInterface.swift
//  ipscanner
//
//  Created by Matus Barta on 11/07/2026.
//

import Darwin
import Foundation
import SystemConfiguration

nonisolated struct NetworkInterface: Identifiable, Hashable, Sendable {
    let name: String
    let address: String
    let netmask: String

    let type: NetworkInterfaceType
    let localizedName: String

    var id: String {
        "\(name)|\(address)"
    }

    var isPhysical: Bool {
        type.isPhysical
    }

    var cidrPrefix: Int {
        netmask
            .split(separator: ".")
            .compactMap { Int($0) }
            .reduce(0) { $0 + $1.nonzeroBitCount }
    }

    var networkAddress: String? {
        let ipOctets = address
            .split(separator: ".")
            .compactMap { UInt8($0) }

        let maskOctets = netmask
            .split(separator: ".")
            .compactMap { UInt8($0) }

        guard ipOctets.count == 4,
              maskOctets.count == 4
        else {
            return nil
        }

        let network = zip(ipOctets, maskOctets)
            .map { $0 & $1 }

        return network
            .map(String.init)
            .joined(separator: ".")
    }

    var subnet: String? {
        guard let networkAddress else {
            return nil
        }

        return "\(networkAddress)/\(cidrPrefix)"
    }

    var displayName: String {
        let interfaceDescription = "\(localizedName) (\(name))"
        if let subnet {
            return "\(interfaceDescription) – \(subnet)"
        }
        return "\(interfaceDescription) – \(address)"
    }
}

nonisolated enum NetworkInterfaces {
    private struct InterfaceMetadata: Sendable {
        let localizedName: String
        let type: NetworkInterfaceType
    }

    static func getAll() -> [NetworkInterface] {
        let metadata = loadInterfaceMetadata()

        var interfaces: [NetworkInterface] = []
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0,
              let firstAddr = ifaddr
        else {
            return []
        }

        defer {
            freeifaddrs(ifaddr)
        }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee

            guard let addr = interface.ifa_addr else {
                continue
            }

            guard addr.pointee.sa_family == UInt8(AF_INET) else {
                continue
            }

            guard let netmask = interface.ifa_netmask else {
                continue
            }

            let flags = Int32(interface.ifa_flags)

            guard (flags & IFF_UP) != 0 else {
                continue
            }

            guard (flags & IFF_RUNNING) != 0 else {
                continue
            }

            guard (flags & IFF_LOOPBACK) == 0 else {
                continue
            }

            let name = String(cString: interface.ifa_name)

            var addressBuffer = [CChar](
                repeating: 0,
                count: Int(NI_MAXHOST)
            )

            var netmaskBuffer = [CChar](
                repeating: 0,
                count: Int(NI_MAXHOST)
            )

            let addressResult = getnameinfo(
                addr,
                socklen_t(addr.pointee.sa_len),
                &addressBuffer,
                socklen_t(addressBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            guard addressResult == 0 else { continue }

            let netmaskResult = getnameinfo(
                netmask,
                socklen_t(netmask.pointee.sa_len),
                &netmaskBuffer,
                socklen_t(netmaskBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            guard netmaskResult == 0,
                  let address = String(utf8String: addressBuffer),
                  let netmask = String(utf8String: netmaskBuffer)
            else {
                continue
            }

            let interfaceMetadata = metadata[name] ?? fallbackMetadata(for: name)

            interfaces.append(
                NetworkInterface(
                    name: name,
                    address: address,
                    netmask: netmask,
                    type: interfaceMetadata.type,
                    localizedName: interfaceMetadata.localizedName
                )
            )
        }

        return interfaces
    }

    private static func loadInterfaceMetadata() -> [String: InterfaceMetadata] {
        let systemInterfaces = SCNetworkInterfaceCopyAll() as NSArray
        var result: [String: InterfaceMetadata] = [:]

        for case let systemInterface as SCNetworkInterface in systemInterfaces {
            guard let bsdName = SCNetworkInterfaceGetBSDName(systemInterface) as String?
            else {
                continue
            }

            let localizedName = SCNetworkInterfaceGetLocalizedDisplayName(systemInterface) as String? ?? bsdName

            let systemType = SCNetworkInterfaceGetInterfaceType(systemInterface) as String?
            result[bsdName] = InterfaceMetadata(localizedName: localizedName, type: mapInterfaceType(systemType, localizedName: localizedName, bsdName: bsdName))
        }

        return result
    }

    private static func mapInterfaceType(_ systemType: String?, localizedName: String, bsdName: String) -> NetworkInterfaceType {
        let type = systemType?.lowercased() ?? ""
        let label = localizedName.lowercased()

        if type.contains("ieee80211") || type.contains("airport") || label.contains("wi-fi") || label.contains("wifi") {
            return .wifi
        }
        if type.contains("ethernet") || label.contains("ethernet") || label.contains("lan") {
            return .ethernet
        }
        if type.contains("ppp") || type.contains("vpn") || label.contains("vpn") {
            return .vpn
        }
        if type.contains("bluetooth") || label.contains("bluetooth") {
            return .bluetooth
        }
        if type.contains("wwan") || label.contains("cellular") {
            return .cellular
        }
        return classifyByBSDName(bsdName)
    }

    private static func fallbackMetadata(for bsdName: String) -> InterfaceMetadata {
        let type = classifyByBSDName(bsdName)
        return InterfaceMetadata(localizedName: type.displayName, type: type)
    }

    private static func classifyByBSDName(_ name: String) -> NetworkInterfaceType {
        if name.hasPrefix("utun") || name.hasPrefix("tun") || name.hasPrefix("tap") || name.hasPrefix("ipsec") {
            return .vpn
        }
        if name.hasPrefix("bridge") {
            return .bridge
        }
        if name == "lo0" {
            return .loopback
        }
        if name.hasPrefix("gif") || name.hasPrefix("stf") {
            return .tunnel
        }

        // Do not classify every en* interface as physical here.
        // en* may represent Wi-Fi, built-in Ethernet, USB Ethernet, Thunderbolt networking, virtual adapters, or other hardware.

        // SystemConfiguration metadata is preferred for en* devices.
        return .other
    }
}
