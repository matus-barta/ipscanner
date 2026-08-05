//
//  PortScanSession.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation
@preconcurrency import Network

final nonisolated class PortScanSession<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()

    private var continuation: CheckedContinuation<T, Never>?
    private var connection: NWConnection?
    private var finished = false
    private var pendingValue: T?

    func setContinuation(_ continuation: CheckedContinuation<T, Never>) {
        var valueToResume: T?

        lock.lock()

        if finished {
            valueToResume = pendingValue
        } else {
            self.continuation = continuation
        }

        lock.unlock()

        if let valueToResume {
            continuation.resume(returning: valueToResume)
        }
    }

    func setConnection(_ connection: NWConnection) {
        var shouldCancel = false

        lock.lock()

        if finished {
            shouldCancel = true
        } else {
            self.connection = connection
        }

        lock.unlock()

        if shouldCancel {
            connection.cancel()
        }
    }

    func resume(_ value: T) {
        var continuationToResume: CheckedContinuation<T, Never>?
        var connectionToCancel: NWConnection?

        lock.lock()

        guard !finished else {
            lock.unlock()
            return
        }

        finished = true
        pendingValue = value

        continuationToResume = continuation
        continuation = nil

        connectionToCancel = connection
        connection = nil

        lock.unlock()

        connectionToCancel?.cancel()
        continuationToResume?.resume(returning: value)
    }

    func cancel(returning value: T) {
        resume(value)
    }
}
