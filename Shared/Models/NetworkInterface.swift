//
//  NetworkInterface.swift
//  IP Scanner
//
//  Created by Matus Barta on 11/07/2026.
//

import Darwin
import Foundation

#if os(macOS)
    import SystemConfiguration
#endif

nonisolated struct NetworkInterface:
    Identifiable,
    Hashable,
    Sendable
{
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

        let networkOctets = zip(
            ipOctets,
            maskOctets
        )
        .map { addressOctet, maskOctet in
            addressOctet & maskOctet
        }

        return networkOctets
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

// MARK: - Interface discovery

nonisolated enum NetworkInterfaces {
    private struct InterfaceMetadata: Sendable {
        let localizedName: String
        let type: NetworkInterfaceType
    }

    static func getAll() -> [NetworkInterface] {
        let metadata = loadInterfaceMetadata()

        var interfaces: [NetworkInterface] = []
        var interfaceList: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfaceList) == 0,
              let firstInterface = interfaceList
        else {
            return []
        }

        defer {
            freeifaddrs(interfaceList)
        }

        for pointer in sequence(
            first: firstInterface,
            next: { $0.pointee.ifa_next }
        ) {
            let rawInterface = pointer.pointee

            guard let addressPointer =
                rawInterface.ifa_addr
            else {
                continue
            }

            guard addressPointer.pointee.sa_family
                == UInt8(AF_INET)
            else {
                continue
            }

            guard let netmaskPointer =
                rawInterface.ifa_netmask
            else {
                continue
            }

            let flags = Int32(
                rawInterface.ifa_flags
            )

            guard (flags & IFF_UP) != 0,
                  (flags & IFF_RUNNING) != 0,
                  (flags & IFF_LOOPBACK) == 0
            else {
                continue
            }

            let name = String(
                cString: rawInterface.ifa_name
            )

            guard let address = numericAddress(
                from: addressPointer
            ),
                let netmask = numericAddress(
                    from: netmaskPointer
                )
            else {
                continue
            }

            let interfaceMetadata =
                metadata[name]
                    ?? fallbackMetadata(
                        for: name
                    )

            interfaces.append(
                NetworkInterface(
                    name: name,
                    address: address,
                    netmask: netmask,
                    type: interfaceMetadata.type,
                    localizedName:
                    interfaceMetadata.localizedName
                )
            )
        }

        return interfaces
    }

    // MARK: - Shared address conversion

    private static func numericAddress(
        from addressPointer: UnsafePointer<sockaddr>
    ) -> String? {
        var buffer = [CChar](
            repeating: 0,
            count: Int(NI_MAXHOST)
        )

        let result = getnameinfo(
            addressPointer,
            socklen_t(addressPointer.pointee.sa_len),
            &buffer,
            socklen_t(buffer.count),
            nil,
            0,
            NI_NUMERICHOST
        )

        guard result == 0 else {
            return nil
        }

        return String(utf8String: buffer)
    }

    // MARK: - Platform metadata

    private static func loadInterfaceMetadata()
        -> [String: InterfaceMetadata]
    {
        #if os(macOS)
            loadMacInterfaceMetadata()
        #else
            [:]
        #endif
    }

    #if os(macOS)

        private static func loadMacInterfaceMetadata()
            -> [String: InterfaceMetadata]
        {
            let systemInterfaces =
                SCNetworkInterfaceCopyAll() as NSArray

            var result:
                [String: InterfaceMetadata] = [:]

            for case let systemInterface
                as SCNetworkInterface
            in systemInterfaces {
                guard let bsdName =
                    SCNetworkInterfaceGetBSDName(
                        systemInterface
                    ) as String?
                else {
                    continue
                }

                let localizedName =
                    SCNetworkInterfaceGetLocalizedDisplayName(
                        systemInterface
                    ) as String?
                    ?? bsdName

                let systemType =
                    SCNetworkInterfaceGetInterfaceType(
                        systemInterface
                    ) as String?

                result[bsdName] = InterfaceMetadata(
                    localizedName: localizedName,
                    type: mapMacInterfaceType(
                        systemType,
                        localizedName: localizedName,
                        bsdName: bsdName
                    )
                )
            }

            return result
        }

        private static func mapMacInterfaceType(
            _ systemType: String?,
            localizedName: String,
            bsdName: String
        ) -> NetworkInterfaceType {
            let type =
                systemType?.lowercased() ?? ""

            let label =
                localizedName.lowercased()

            if type.contains("ieee80211")
                || type.contains("airport")
                || label.contains("wi-fi")
                || label.contains("wifi")
            {
                return .wifi
            }

            if type.contains("ethernet")
                || label.contains("ethernet")
                || label.contains("lan")
            {
                return .ethernet
            }

            if type.contains("ppp")
                || type.contains("vpn")
                || label.contains("vpn")
            {
                return .vpn
            }

            if type.contains("bluetooth")
                || label.contains("bluetooth")
            {
                return .bluetooth
            }

            if type.contains("wwan")
                || label.contains("cellular")
            {
                return .cellular
            }

            return classifyByBSDName(bsdName)
        }

    #endif

    // MARK: - Shared fallback classification

    private static func fallbackMetadata(
        for bsdName: String
    ) -> InterfaceMetadata {
        let type = classifyByBSDName(
            bsdName
        )

        return InterfaceMetadata(
            localizedName: type.displayName,
            type: type
        )
    }

    private static func classifyByBSDName(
        _ name: String
    ) -> NetworkInterfaceType {
        if name.hasPrefix("utun")
            || name.hasPrefix("tun")
            || name.hasPrefix("tap")
            || name.hasPrefix("ipsec")
        {
            return .vpn
        }

        if name.hasPrefix("bridge") {
            return .bridge
        }

        if name == "lo0" {
            return .loopback
        }

        if name.hasPrefix("gif")
            || name.hasPrefix("stf")
        {
            return .tunnel
        }

        #if os(iOS)
            /*
             On iPadOS, en0 is normally the Wi-Fi interface.
             Wired adapters may also use an en* interface, so this
             should be treated as an approximation until a dedicated
             iPad network-path provider is implemented.
             */
            if name == "en0" {
                return .wifi
            }
        #endif

        return .other
    }
}
