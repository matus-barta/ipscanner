//
//  ContinuationBox.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

final nonisolated class ContinuationBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Never>?

    init(_ continuation: CheckedContinuation<T, Never>) {
        self.continuation = continuation
    }

    func resume(_ value: sending T) {
        lock.lock()

        guard let continuation else {
            lock.unlock()
            return
        }

        self.continuation = nil
        lock.unlock()

        continuation.resume(returning: value)
    }
}
