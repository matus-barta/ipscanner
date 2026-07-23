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

    var scanProfile: ScanProfile
    var connectionTimeout: TimeInterval

    private(set) var reverseDNSEnabled: Bool
    private(set) var netBIOSEnabled: Bool
    private(set) var bonjourEnabled: Bool

    let interfaceSelection = InterfaceSelection()

    private var scanTask: Task<Void, Never>?

    private let maxConcurrentHosts = 64
    private let maxConcurrentPortsPerHost = 8

    init() {
        let defaults = UserDefaults.standard

        let profileValue = defaults.string(
            forKey: AppPreferenceKeys.defaultScanProfile
        )

        scanProfile = ScanProfile(
            rawValue: profileValue ?? ""
        ) ?? AppPreferenceDefaults.scanProfile

        if defaults.object(
            forKey: AppPreferenceKeys.connectionTimeout
        ) != nil {
            connectionTimeout = defaults.double(
                forKey: AppPreferenceKeys.connectionTimeout
            )
        } else {
            connectionTimeout =
                AppPreferenceDefaults.connectionTimeout
        }

        reverseDNSEnabled = defaults.object(
            forKey: AppPreferenceKeys.reverseDNSEnabled
        ) == nil
            ? AppPreferenceDefaults.reverseDNSEnabled
            : defaults.bool(
                forKey: AppPreferenceKeys.reverseDNSEnabled
            )

        netBIOSEnabled = defaults.object(
            forKey: AppPreferenceKeys.netBIOSEnabled
        ) == nil
            ? AppPreferenceDefaults.netBIOSEnabled
            : defaults.bool(
                forKey: AppPreferenceKeys.netBIOSEnabled
            )

        bonjourEnabled = defaults.object(
            forKey: AppPreferenceKeys.bonjourEnabled
        ) == nil
            ? AppPreferenceDefaults.bonjourEnabled
            : defaults.bool(
                forKey: AppPreferenceKeys.bonjourEnabled
            )

        interfaceSelection.onSelectionChanged = {
            [weak self] selectedSubnets in
            self?.applySelectedSubnets(selectedSubnets)
        }

        let physicalOnly = defaults.object(
            forKey: AppPreferenceKeys.physicalInterfacesOnly
        ) == nil
            ? AppPreferenceDefaults.physicalInterfacesOnly
            : defaults.bool(
                forKey: AppPreferenceKeys.physicalInterfacesOnly
            )

        interfaceSelection.setPhysicalInterfacesOnly(
            physicalOnly
        )

        interfaceSelection.refresh()

        BonjourResolver.shared.onHostnameFound = {
            [weak self] ip, hostname in
            self?.applyBonjourHostname(
                ip: ip,
                hostname: hostname
            )
        }

        if bonjourEnabled {
            BonjourResolver.shared.start()
        }
    }

    func startScan() {
        guard !isScanning else {
            return
        }

        reloadPersistentSettings()

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

    func refreshInterfaces() {
        interfaceSelection.refresh()
    }

    /// Kept for compatibility with existing buttons and views that still call refreshSubnets().
    func refreshSubnets() {
        refreshInterfaces()
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

    private func applySelectedSubnets(
        _ selectedSubnets: [Subnet]
    ) {
        subnetList = selectedSubnets
        subnets = selectedSubnets
            .map(\.displayValue)
            .joined(separator: ", ")
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

        let ports = scanProfile.ports
        let timeout = connectionTimeout
        let hostConcurrency = maxConcurrentHosts
        let portConcurrency = maxConcurrentPortsPerHost

        let useReverseDNS = reverseDNSEnabled
        let useNetBIOS = netBIOSEnabled
        let useBonjour = bonjourEnabled

        await withTaskGroup(of: HostScanResult.self) { group in
            let initialCount = min(hostConcurrency, hosts.count)

            for index in 0 ..< initialCount {
                let host = hosts[index]

                group.addTask {
                    await HostScanner.scan(
                        host: host,
                        ports: ports,
                        timeout: timeout,
                        maxConcurrentPorts: portConcurrency,
                        reverseDNSEnabled: useReverseDNS,
                        netBIOSEnabled: useNetBIOS,
                        bonjourEnabled: useBonjour
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
                        hostnameSource: result.hostnameSource,
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
                            timeout: timeout,
                            maxConcurrentPorts: portConcurrency
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
        devices[index].hostnameSource = .bonjour
    }

    func exportDevices(
        as format: ExportFormat
    ) {
        DeviceExporter.export(
            devices,
            format: format
        )
    }

    func exportDevice(
        _ device: Device,
        as format: ExportFormat
    ) {
        let safeName = exportFileName(
            for: device,
            format: format
        )

        DeviceExporter.export(
            [device],
            format: format,
            suggestedFileName: safeName
        )
    }

    private func exportFileName(
        for device: Device,
        format: ExportFormat
    ) -> String {
        let sourceName: String = if let hostname = device.hostname,
                                    !hostname.isEmpty
        {
            hostname
        } else {
            device.ip
        }

        let allowedCharacters =
            CharacterSet.alphanumerics
                .union(
                    CharacterSet(
                        charactersIn: "-_"
                    )
                )

        let safeName = sourceName.unicodeScalars
            .map { scalar in
                allowedCharacters.contains(scalar)
                    ? String(scalar)
                    : "-"
            }
            .joined()

        return "\(safeName).\(format.fileExtension)"
    }

    private func reloadPersistentSettings() {
        let defaults = UserDefaults.standard

        if let profileValue = defaults.string(
            forKey: AppPreferenceKeys.defaultScanProfile
        ),
            let profile = ScanProfile(rawValue: profileValue)
        {
            scanProfile = profile
        }

        if defaults.object(
            forKey: AppPreferenceKeys.connectionTimeout
        ) != nil {
            connectionTimeout = defaults.double(
                forKey: AppPreferenceKeys.connectionTimeout
            )
        }

        reverseDNSEnabled = defaults.object(
            forKey: AppPreferenceKeys.reverseDNSEnabled
        ) == nil
            ? AppPreferenceDefaults.reverseDNSEnabled
            : defaults.bool(
                forKey: AppPreferenceKeys.reverseDNSEnabled
            )

        netBIOSEnabled = defaults.object(
            forKey: AppPreferenceKeys.netBIOSEnabled
        ) == nil
            ? AppPreferenceDefaults.netBIOSEnabled
            : defaults.bool(
                forKey: AppPreferenceKeys.netBIOSEnabled
            )

        bonjourEnabled = defaults.object(
            forKey: AppPreferenceKeys.bonjourEnabled
        ) == nil
            ? AppPreferenceDefaults.bonjourEnabled
            : defaults.bool(
                forKey: AppPreferenceKeys.bonjourEnabled
            )

        let physicalOnly = defaults.object(
            forKey: AppPreferenceKeys.physicalInterfacesOnly
        ) == nil
            ? AppPreferenceDefaults.physicalInterfacesOnly
            : defaults.bool(
                forKey: AppPreferenceKeys.physicalInterfacesOnly
            )

        if physicalOnly !=
            interfaceSelection.physicalInterfacesOnly
        {
            interfaceSelection.setPhysicalInterfacesOnly(
                physicalOnly
            )
        }

        if bonjourEnabled {
            BonjourResolver.shared.start()
        }
    }

    func device(
        withID id: Device.ID?
    ) -> Device? {
        guard let id else {
            return nil
        }

        return devices.first {
            $0.id == id
        }
    }

    func clearResults() {
        guard !isScanning else {
            return
        }

        devices.removeAll()

        progress = 0
        totalHosts = 0
        scannedHosts = 0
        onlineHosts = 0
    }
}
