//
//  NetworkInterface.swift
//  ipscanner
//
//  Created by Matus Barta on 11/07/2026.
//

import Darwin
import Foundation

struct NetworkInterface: Identifiable, Hashable {
    let id = UUID()

    let name: String
    let address: String
    let netmask: String

    var isPhysical: Bool {
        name.hasPrefix("en")
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
}

enum NetworkInterfaces {
    static func getAll() -> [NetworkInterface] {
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

            getnameinfo(
                addr,
                socklen_t(addr.pointee.sa_len),
                &addressBuffer,
                socklen_t(addressBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            getnameinfo(
                netmask,
                socklen_t(netmask.pointee.sa_len),
                &netmaskBuffer,
                socklen_t(netmaskBuffer.count),
                nil,
                0,
                NI_NUMERICHOST
            )

            guard let address = String(utf8String: addressBuffer) else {
                continue
            }

            guard let netmaskAddress = String(utf8String: netmaskBuffer) else {
                continue
            }

            interfaces.append(
                NetworkInterface(
                    name: name,
                    address: address,
                    netmask: netmaskAddress
                )
            )
        }

        return interfaces
    }
}
