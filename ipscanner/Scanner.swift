import Foundation
import Observation

@MainActor
@Observable
final class Scanner {
    var devices: [Device] = []

    var progress: Double = 0.0
    var isScanning = false

    var subnets: String = ""
    var subnetList: [Subnet] = []

    var totalHosts: Int = 0
    var scannedHosts: Int = 0
    var onlineHosts: Int = 0

    var offlineHosts: Int {
        scannedHosts - onlineHosts
    }

    private var scanTask: Task<Void, Never>?

    private let maxConcurrentHosts = 64
    var connectionTimeout = 0.5
    private let maxConcurrentPortsPerHost = 8

    private let defaultPorts = ScanProfile.standard.ports

    init() {
        refreshSubnets()
        BonjourResolver.shared.onHostnameFound = { [weak self] ip, hostname in
            self?.applyBonjourHostname(
                ip: ip,
                hostname: hostname
            )
        }

        BonjourResolver.shared.start()
    }

    func startScan() {
        guard !isScanning else {
            return
        }

        print("Scanner.startScan()")

        normalizeSubnetInput()

        devices.removeAll()

        let hosts = subnetList.flatMap {
            $0.hosts()
        }

        totalHosts = hosts.count
        scannedHosts = 0
        onlineHosts = 0

        progress = 0
        isScanning = true

        scanTask = Task {
            await scanSubnets()
        }
    }

    func pauseScan() {
        print("Scanner.pauseScan()")
    }

    func stopScan() {
        print("Scanner.stopScan()")

        scanTask?.cancel()
        scanTask = nil

        isScanning = false
    }

    func refreshSubnets() {
        let interfaces = NetworkInterfaces.getAll()

        subnetList = interfaces
            .filter(\.isPhysical)
            .compactMap { interface in
                guard let network = interface.networkAddress else {
                    return nil
                }

                return Subnet(
                    network: network,
                    prefix: interface.cidrPrefix
                )
            }

        subnetList = Array(Set(subnetList))
            .sorted {
                "\($0.network)/\($0.prefix)"
                    < "\($1.network)/\($1.prefix)"
            }

        subnets = subnetList
            .map { "\($0.network)/\($0.prefix)" }
            .joined(separator: ", ")
    }

    func parseSubnets() {
        subnetList = subnets
            .split(separator: ",")
            .compactMap { part in
                Subnet.parse(String(part))
            }

        print("=== Parsed subnets ===")

        for subnet in subnetList {
            print("\(subnet.network)/\(subnet.prefix)")
        }

        print("Total: \(subnetList.count)")
    }

    func normalizeSubnetInput() {
        parseSubnets()

        let normalized = Array(Set(subnetList))
            .sorted {
                $0.displayValue < $1.displayValue
            }

        subnetList = normalized

        subnets = normalized
            .map(\.displayValue)
            .joined(separator: ", ")

        print("=== Normalized subnet input ===")
        print(subnets)
    }

    private func scanSubnets() async {
        defer {
            isScanning = false
            scanTask = nil
        }

        let hosts = subnetList.flatMap {
            $0.hosts()
        }

        guard !hosts.isEmpty else {
            progress = 0
            return
        }

        let ports = defaultPorts
        let timeout = connectionTimeout
        let hostConcurrency = maxConcurrentHosts
        let portConcurrency = maxConcurrentPortsPerHost

        await withTaskGroup(of: HostScanResult.self) { group in
            let initialCount = min(hostConcurrency, hosts.count)

            for index in 0 ..< initialCount {
                let host = hosts[index]

                group.addTask {
                    await HostScanner.scan(
                        host: host,
                        ports: ports,
                        timeout: timeout,
                        maxConcurrentPorts: portConcurrency
                    )
                }
            }

            var nextIndex = initialCount

            while let result = await group.next() {
                if Task.isCancelled {
                    group.cancelAll()
                    return
                }

                scannedHosts += 1

                if result.responded {
                    onlineHosts += 1

                    let manufacturer = MacVendorResolver.vendor(for: result.mac)

                    let device = Device(
                        ip: result.host,
                        hostname: result.hostname,
                        mac: result.mac,
                        manufacturer: manufacturer,
                        openPorts: result.openPorts
                    )

                    devices.append(device)

                    devices.sort {
                        $0.ipSortable < $1.ipSortable
                    }
                }

                progress = Double(scannedHosts) / Double(totalHosts)

                if nextIndex < hosts.count {
                    let host = hosts[nextIndex]
                    nextIndex += 1

                    group.addTask {
                        await HostScanner.scan(
                            host: host,
                            ports: ports,
                            timeout: 1.0
                        )
                    }
                }
            }
        }

        progress = 1.0
    }

    private func applyBonjourHostname(
        ip: String,
        hostname: String
    ) {
        guard let index = devices.firstIndex(
            where: { $0.ip == ip }
        ) else {
            return
        }

        // Do not overwrite NetBIOS / reverse DNS names.
        guard devices[index].hostname == nil ||
            devices[index].hostname?.isEmpty == true
        else {
            return
        }

        devices[index].hostname = hostname
    }
}
