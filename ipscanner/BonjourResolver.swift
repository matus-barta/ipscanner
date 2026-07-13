//
//  BonjourResolver.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Darwin
@preconcurrency import Foundation

final nonisolated class BonjourResolver: NSObject, NetServiceBrowserDelegate, NetServiceDelegate, @unchecked Sendable {
    static let shared = BonjourResolver()

    private let lock = NSLock()

    private var browsers: [NetServiceBrowser] = []
    private var resolvingServices: [String: NetService] = [:]

    private var hostnamesByIP: [String: String] = [:]
    private var prioritiesByIP: [String: Int] = [:]

    private var didStart = false

    var onHostnameFound: (@MainActor (String, String) -> Void)?

    override private init() {
        super.init()
    }

    func start() {
        lock.lock()

        if didStart {
            lock.unlock()
            return
        }

        didStart = true
        lock.unlock()

        let serviceTypes = [
            "_airplay._tcp.",
            "_raop._tcp.",
            "_companion-link._tcp.",
            "_home-sharing._tcp.",
            "_apple-mobdev2._tcp.",

            // Useful later if they appear on network
            "_ssh._tcp.",
            "_smb._tcp.",
            "_workstation._tcp.",
            "_device-info._tcp.",
            "_adisk._tcp.",
            
            "_googlecast._tcp.",
            "_androidtvremote2._tcp."

        ]

        for type in serviceTypes {
            browse(type: type)
        }
    }

    func hostname(for ip: String) -> String? {
        lock.lock()
        let value = hostnamesByIP[ip]
        lock.unlock()

        return value
    }

    private func browse(type: String) {
        let browser = NetServiceBrowser()
        browser.delegate = self
        browser.searchForServices(
            ofType: type,
            inDomain: "local."
        )

        lock.lock()
        browsers.append(browser)
        lock.unlock()

        print("Bonjour browsing \(type)")
    }

    func netServiceBrowser(
        _: NetServiceBrowser,
        didFind service: NetService,
        moreComing _: Bool
    ) {
        service.delegate = self

        let key = serviceKey(service)

        lock.lock()
        resolvingServices[key] = service
        lock.unlock()

        service.resolve(withTimeout: 3.0)
    }

    func netServiceBrowser(
        _: NetServiceBrowser,
        didRemove service: NetService,
        moreComing _: Bool
    ) {
        let key = serviceKey(service)

        lock.lock()
        resolvingServices.removeValue(forKey: key)
        lock.unlock()
    }

    func netServiceDidResolveAddress(
        _ sender: NetService
    ) {
        let displayName = displayName(
            for: sender.name,
            type: sender.type
        )

        let priority = servicePriority(
            for: sender.type
        )

        guard let addresses = sender.addresses else {
            cleanup(sender)
            return
        }

        for address in addresses {
            guard let ip = Self.ipv4Address(from: address) else {
                continue
            }

            addHostname(
                displayName,
                for: ip,
                priority: priority
            )
        }

        cleanup(sender)
    }

    func netService(
        _ sender: NetService,
        didNotResolve _: [String: NSNumber]
    ) {
        cleanup(sender)
    }

    private func addHostname(
        _ hostname: String,
        for ip: String,
        priority: Int
    ) {
        var callback: (@MainActor (String, String) -> Void)?
        var shouldNotify = false

        lock.lock()

        let currentPriority = prioritiesByIP[ip] ?? -1
        let oldHostname = hostnamesByIP[ip]

        if priority >= currentPriority {
            hostnamesByIP[ip] = hostname
            prioritiesByIP[ip] = priority

            if oldHostname != hostname {
                shouldNotify = true
                callback = onHostnameFound
            }
        }

        lock.unlock()

        if shouldNotify {
            print("Bonjour \(ip) -> \(hostname)")

            if let callback {
                Task { @MainActor in
                    callback(ip, hostname)
                }
            }
        }
    }

    private func cleanup(
        _ service: NetService
    ) {
        let key = serviceKey(service)

        lock.lock()
        resolvingServices.removeValue(forKey: key)
        lock.unlock()
    }

    private func serviceKey(
        _ service: NetService
    ) -> String {
        "\(service.name)|\(service.type)|\(service.domain)"
    }

    private func displayName(
        for name: String,
        type: String
    ) -> String {
        if type == "_raop._tcp." {
            if let atIndex = name.firstIndex(of: "@") {
                let afterAt = name.index(after: atIndex)
                return String(name[afterAt...])
            }
        }

        return name
    }

    private func servicePriority(
        for type: String
    ) -> Int {
        switch type {
        case "_airplay._tcp.":
            100

        case "_raop._tcp.":
            90

        case "_companion-link._tcp.":
            80

        case "_home-sharing._tcp.":
            70

        case "_apple-mobdev2._tcp.":
            60

        case "_ssh._tcp.":
            50

        case "_smb._tcp.":
            50

        case "_workstation._tcp.":
            40

        case "_device-info._tcp.":
            40

        case "_adisk._tcp.":
            40

        default:
            10
        }
    }

    private static func ipv4Address(
        from address: Data
    ) -> String? {
        address.withUnsafeBytes { rawBuffer in
            guard rawBuffer.count >= MemoryLayout<sockaddr_in>.size,
                  let baseAddress = rawBuffer.baseAddress
            else {
                return nil
            }

            let sockaddrPointer = baseAddress.assumingMemoryBound(
                to: sockaddr.self
            )

            guard sockaddrPointer.pointee.sa_family == sa_family_t(AF_INET) else {
                return nil
            }

            let ipv4Pointer = baseAddress.assumingMemoryBound(
                to: sockaddr_in.self
            )

            var ipv4Address = ipv4Pointer.pointee.sin_addr

            var buffer = [CChar](
                repeating: 0,
                count: Int(INET_ADDRSTRLEN)
            )

            guard inet_ntop(
                AF_INET,
                &ipv4Address,
                &buffer,
                socklen_t(INET_ADDRSTRLEN)
            ) != nil
            else {
                return nil
            }

            return String(utf8String: buffer)
        }
    }
}
