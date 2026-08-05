//
//  ReverseDNSResolver.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Darwin
import Foundation

nonisolated enum ReverseDNSResolver {
    static func hostname(for ip: String) -> String? {
        var addr = sockaddr_in()

        addr.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = 0

        let conversionResult = ip.withCString { cString in
            inet_pton(AF_INET, cString, &addr.sin_addr)
        }

        guard conversionResult == 1 else {
            return nil
        }

        var hostnameBuffer = [CChar](
            repeating: 0,
            count: Int(NI_MAXHOST)
        )

        var addrCopy = addr

        let result = withUnsafePointer(to: &addrCopy) { pointer in
            pointer.withMemoryRebound(
                to: sockaddr.self,
                capacity: 1
            ) { sockaddrPointer in
                getnameinfo(
                    sockaddrPointer,
                    socklen_t(MemoryLayout<sockaddr_in>.size),
                    &hostnameBuffer,
                    socklen_t(hostnameBuffer.count),
                    nil,
                    0,
                    NI_NAMEREQD
                )
            }
        }

        guard result == 0 else {
            return nil
        }

        return String(utf8String: hostnameBuffer)
    }
}
