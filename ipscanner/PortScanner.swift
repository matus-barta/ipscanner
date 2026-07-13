//
//  PortState.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation
@preconcurrency import Network

enum PortState: Hashable,Sendable {
    case open
    case closed
    case timeout
    case failed(String)
}

struct PortScanResult: Hashable, Sendable {
    let host: String
    let port: Int
    let state: PortState
}

enum PortScanner {
    static func scan(
        host: String,
        port: Int,
        timeout: TimeInterval = 1.0
    ) async -> PortScanResult {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            return PortScanResult(
                host: host,
                port: port,
                state: .failed("Invalid port")
            )
        }

        return await withCheckedContinuation { continuation in
            let finisher = ContinuationFinisher(continuation)

            let connection = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: .tcp
            )

            let queue = DispatchQueue.global(qos: .utility)

            queue.asyncAfter(deadline: .now() + timeout) {
                connection.cancel()

                finisher.resume(
                    PortScanResult(
                        host: host,
                        port: port,
                        state: .timeout
                    )
                )
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()

                    finisher.resume(
                        PortScanResult(
                            host: host,
                            port: port,
                            state: .open
                        )
                    )

                case let .failed(error):
                    connection.cancel()

                    if case let .posix(posixError) = error,
                       posixError == .ECONNREFUSED
                    {
                        finisher.resume(
                            PortScanResult(
                                host: host,
                                port: port,
                                state: .closed
                            )
                        )
                    } else {
                        finisher.resume(
                            PortScanResult(
                                host: host,
                                port: port,
                                state: .failed(String(describing: error))
                            )
                        )
                    }

                default:
                    break
                }
            }

            connection.start(queue: queue)
        }
    }
}

private final class ContinuationFinisher<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Never>?

    init(_ continuation: CheckedContinuation<T, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: T) {
        lock.lock()
        defer {
            lock.unlock()
        }

        guard let continuation else {
            return
        }

        self.continuation = nil
        continuation.resume(returning: value)
    }
}
