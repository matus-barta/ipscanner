//
//  NetBIOSNameEntry.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation
@preconcurrency import Network

nonisolated struct NetBIOSNameEntry: Hashable, Sendable {
    let name: String
    let suffix: UInt8
    let flags: UInt16

    var isGroup: Bool {
        (flags & 0x8000) != 0
    }
}

nonisolated struct NetBIOSLookupResult: Hashable, Sendable {
    let hostname: String
    let entries: [NetBIOSNameEntry]
}

nonisolated enum NetBIOSResolver {
    static func hostname(
        for host: String,
        timeout: TimeInterval = 1.0
    ) async -> String? {
        let result = await lookup(
            host: host,
            timeout: timeout
        )
        return result?.hostname
    }

    static func lookup(
        host: String,
        timeout: TimeInterval = 1.0
    ) async -> NetBIOSLookupResult? {
        guard let port = NWEndpoint.Port(rawValue: 137) else {
            return nil
        }

        let transactionID = UInt16.random(in: 1 ... UInt16.max)
        let packet = buildNodeStatusQuery(transactionID: transactionID)

        let session = PortScanSession<NetBIOSLookupResult?>()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                session.setContinuation(continuation)

                if Task.isCancelled {
                    session.cancel(returning: nil)
                    return
                }

                let connection = NWConnection(
                    host: NWEndpoint.Host(host),
                    port: port,
                    using: .udp
                )

                session.setConnection(connection)

                let queue = DispatchQueue.global(qos: .utility)

                queue.asyncAfter(deadline: .now() + timeout) {
                    print("NetBIOS \(host) timeout")
                    session.resume(nil)
                }

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        connection.receiveMessage { data, _, _, _ in
                            guard let data,
                                  let result = parseNodeStatusResponse(
                                      data,
                                      expectedTransactionID: transactionID
                                  )
                            else {
                                session.resume(nil)
                                return
                            }

                            session.resume(result)
                        }

                        connection.send(
                            content: packet,
                            completion: .contentProcessed { error in
                                if error != nil {
                                    session.resume(nil)
                                }
                            }
                        )

                    case .failed:
                        session.resume(nil)

                    case .cancelled:
                        session.resume(nil)

                    default:
                        break
                    }
                }

                connection.start(queue: queue)
            }
        } onCancel: {
            session.cancel(returning: nil)
        }
    }

    private static func buildNodeStatusQuery(
        transactionID: UInt16
    ) -> Data {
        var data = Data()

        func appendUInt16(_ value: UInt16) {
            data.append(UInt8((value >> 8) & 0xFF))
            data.append(UInt8(value & 0xFF))
        }

        appendUInt16(transactionID) // Transaction ID
        appendUInt16(0x0000) // Flags: query
        appendUInt16(0x0001) // Questions
        appendUInt16(0x0000) // Answer RRs
        appendUInt16(0x0000) // Authority RRs
        appendUInt16(0x0000) // Additional RRs

        let encodedName = encodeNetBIOSWildcardName()

        data.append(UInt8(encodedName.count))
        data.append(contentsOf: encodedName)
        data.append(0x00)

        appendUInt16(0x0021) // QTYPE: NBSTAT
        appendUInt16(0x0001) // QCLASS: IN

        return data
    }

    private static func encodeNetBIOSName(
        _ name: String,
        suffix: UInt8
    ) -> [UInt8] {
        var raw = Array(
            name.uppercased().utf8.prefix(15)
        )

        while raw.count < 15 {
            raw.append(0x20)
        }

        raw.append(suffix)

        var encoded: [UInt8] = []

        for byte in raw {
            let high = (byte >> 4) & 0x0F
            let low = byte & 0x0F

            encoded.append(0x41 + high)
            encoded.append(0x41 + low)
        }

        return encoded
    }

    private static func parseNodeStatusResponse(
        _ data: Data,
        expectedTransactionID: UInt16
    ) -> NetBIOSLookupResult? {
        let bytes = Array(data)

        guard bytes.count >= 12 else {
            return nil
        }

        let transactionID = readUInt16(bytes, at: 0)

        guard transactionID == expectedTransactionID else {
            print("NBNS parse: transaction ID mismatch")
            return nil
        }

        let questionCount = readUInt16(bytes, at: 4)
        let answerCount = readUInt16(bytes, at: 6)

        guard answerCount > 0 else {
            print("NBNS parse: no answers")
            return nil
        }

        var offset = 12

        // Skip questions only if QDCOUNT > 0.
        for _ in 0 ..< questionCount {
            guard skipDNSName(bytes, offset: &offset) else {
                print("NBNS parse: failed to skip question name")
                return nil
            }

            guard offset + 4 <= bytes.count else {
                return nil
            }

            offset += 4 // QTYPE + QCLASS
        }

        // Now parse first answer.
        guard skipDNSName(bytes, offset: &offset) else {
            print("NBNS parse: failed to skip answer name")
            return nil
        }

        guard offset + 10 <= bytes.count else {
            return nil
        }

        let rrType = readUInt16(bytes, at: offset)
        offset += 2

        // CLASS
        offset += 2

        // TTL
        offset += 4

        let rdLength = Int(readUInt16(bytes, at: offset))
        offset += 2

        guard rrType == 0x0021 else {
            print("NBNS parse: unexpected rrType \(String(format: "%04X", rrType))")
            return nil
        }

        guard offset + rdLength <= bytes.count else {
            print("NBNS parse: invalid rdLength")
            return nil
        }

        guard offset < bytes.count else {
            return nil
        }

        let nameCount = Int(bytes[offset])
        offset += 1

        var entries: [NetBIOSNameEntry] = []

        for _ in 0 ..< nameCount {
            guard offset + 18 <= bytes.count else {
                break
            }

            let nameBytes = bytes[offset ..< (offset + 15)]
            offset += 15

            let suffix = bytes[offset]
            offset += 1

            let flags = readUInt16(bytes, at: offset)
            offset += 2

            let name = String(
                bytes: nameBytes,
                encoding: .ascii
            )?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard !name.isEmpty,
                  name != "*"
            else {
                continue
            }

            entries.append(
                NetBIOSNameEntry(
                    name: name,
                    suffix: suffix,
                    flags: flags
                )
            )
        }

        guard !entries.isEmpty else {
            return nil
        }

        let preferred = entries.first {
            $0.suffix == 0x00 && !$0.isGroup
        } ?? entries.first {
            !$0.isGroup
        } ?? entries[0]

        return NetBIOSLookupResult(
            hostname: preferred.name,
            entries: entries
        )
    }

    private static func skipDNSName(
        _ bytes: [UInt8],
        offset: inout Int
    ) -> Bool {
        while offset < bytes.count {
            let length = Int(bytes[offset])

            // Compression pointer
            if (length & 0xC0) == 0xC0 {
                offset += 2
                return offset <= bytes.count
            }

            offset += 1

            if length == 0 {
                return true
            }

            offset += length

            if offset > bytes.count {
                return false
            }
        }

        return false
    }

    private static func readUInt16(
        _ bytes: [UInt8],
        at offset: Int
    ) -> UInt16 {
        UInt16(bytes[offset]) << 8 | UInt16(bytes[offset + 1])
    }

    private static func encodeNetBIOSWildcardName() -> [UInt8] {
        var raw: [UInt8] = []

        // Wildcard name "*"
        raw.append(0x2A)

        // For NBSTAT wildcard query, pad with NULL bytes, not spaces.
        while raw.count < 16 {
            raw.append(0x00)
        }

        var encoded: [UInt8] = []

        for byte in raw {
            let high = (byte >> 4) & 0x0F
            let low = byte & 0x0F

            encoded.append(0x41 + high)
            encoded.append(0x41 + low)
        }

        return encoded
    }
}

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        append(UInt8((value >> 8) & 0xFF))
        append(UInt8(value & 0xFF))
    }
}
