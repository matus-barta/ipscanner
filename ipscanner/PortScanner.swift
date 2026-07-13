//
//  PortScanner.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation
@preconcurrency import Network

nonisolated enum PortState: Hashable, Sendable {
    case open
    case closed
    case timeout
    case cancelled
    case failed(String)
}

nonisolated struct PortScanResult: Hashable, Sendable {
    let host: String
    let port: UInt16
    let state: PortState
}

nonisolated enum PortScanner {
    static func scan(
        host: String,
        port: UInt16,
        timeout: TimeInterval
    ) async -> PortScanResult {
        guard port != 0,
              let nwPort = NWEndpoint.Port(rawValue: UInt16(port))
        else {
            return PortScanResult(
                host: host,
                port: port,
                state: .failed("Invalid port")
            )
        }

        let session = PortScanSession<PortScanResult>()

        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                session.setContinuation(continuation)

                if Task.isCancelled {
                    session.cancel(
                        returning: PortScanResult(
                            host: host,
                            port: port,
                            state: .cancelled
                        )
                    )
                    return
                }

                let connection = NWConnection(
                    host: NWEndpoint.Host(host),
                    port: nwPort,
                    using: .tcp
                )

                session.setConnection(connection)

                let queue = DispatchQueue.global(qos: .utility)

                queue.asyncAfter(deadline: .now() + timeout) {
                    session.resume(
                        PortScanResult(
                            host: host,
                            port: port,
                            state: .timeout
                        )
                    )
                }

                connection.stateUpdateHandler = { state in
                    // print("\(host):\(port) state = \(state)")

                    switch state {
                    case .ready:
                        session.resume(
                            PortScanResult(
                                host: host,
                                port: port,
                                state: .open
                            )
                        )

                    case let .waiting(error):
                        if case let .posix(posixError) = error,
                           posixError == .ECONNREFUSED
                        {
                            session.resume(
                                PortScanResult(
                                    host: host,
                                    port: port,
                                    state: .closed
                                )
                            )
                        }

                    case let .failed(error):
                        if case let .posix(posixError) = error,
                           posixError == .ECONNREFUSED
                        {
                            session.resume(
                                PortScanResult(
                                    host: host,
                                    port: port,
                                    state: .closed
                                )
                            )
                        } else {
                            session.resume(
                                PortScanResult(
                                    host: host,
                                    port: port,
                                    state: .failed(String(describing: error))
                                )
                            )
                        }

                    case .cancelled:
                        session.resume(
                            PortScanResult(
                                host: host,
                                port: port,
                                state: .cancelled
                            )
                        )

                    default:
                        break
                    }
                }

                connection.start(queue: queue)
            }
        } onCancel: {
            session.cancel(
                returning: PortScanResult(
                    host: host,
                    port: port,
                    state: .cancelled
                )
            )
        }
    }
}
