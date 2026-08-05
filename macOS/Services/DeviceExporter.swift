//
//  DeviceExporter.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import AppKit
import Foundation

@MainActor
enum DeviceExporter {
    static func export(
        _ devices: [Device],
        format: ExportFormat,
        suggestedFileName: String? = nil
    ) {
        guard !devices.isEmpty else {
            return
        }

        do {
            let data = try exportData(
                devices,
                format: format
            )

            let savePanel = NSSavePanel()

            savePanel.title = "Export Scan Results"
            savePanel.message = exportMessage(
                deviceCount: devices.count,
                format: format
            )

            savePanel.nameFieldLabel = "Export as:"
            savePanel.nameFieldStringValue =
                suggestedFileName
                    ?? defaultFileName(format: format)

            savePanel.allowedContentTypes = [
                format.contentType,
            ]

            savePanel.canCreateDirectories = true
            savePanel.isExtensionHidden = false
            savePanel.allowsOtherFileTypes = false

            guard savePanel.runModal() == .OK,
                  let destinationURL = savePanel.url
            else {
                return
            }

            try data.write(
                to: destinationURL,
                options: .atomic
            )
        } catch {
            presentExportError(error)
        }
    }

    static func exportData(
        _ devices: [Device],
        format: ExportFormat
    ) throws -> Data {
        let sortedDevices = devices.sorted {
            $0.ipSortable < $1.ipSortable
        }

        switch format {
        case .csv:
            return csvData(for: sortedDevices)

        case .json:
            return try jsonData(for: sortedDevices)
        }
    }

    // MARK: - CSV

    private static func csvData(
        for devices: [Device]
    ) -> Data {
        var rows: [String] = []

        rows.append(
            [
                "Hostname",
                "Hostname Source",
                "IP Address",
                "MAC Address",
                "Manufacturer",
                "Open Ports",
                "Open Services",
            ]
            .map(csvField)
            .joined(separator: ",")
        )

        for device in devices {
            let ports = device.openPorts
                .sorted()
                .map(String.init)
                .joined(separator: ", ")

            let services = device.openPorts
                .sorted()
                .map {
                    PortDatabase.name(for: $0)
                        ?? "Unknown service"
                }
                .joined(separator: ", ")

            let row = [
                device.hostname ?? "",
                device.hostnameSource?.displayName ?? "",
                device.ip,
                device.mac ?? "",
                device.manufacturer ?? "",
                ports,
                services,
            ]
            .map(csvField)
            .joined(separator: ",")

            rows.append(row)
        }

        /*
         UTF-8 BOM improves compatibility with Microsoft Excel when
         vendor or hostname values contain non-ASCII characters.
         */
        let byteOrderMark = Data([
            0xEF,
            0xBB,
            0xBF,
        ])

        let text = rows.joined(separator: "\r\n")
            + "\r\n"

        var data = byteOrderMark
        data.append(
            text.data(using: .utf8) ?? Data()
        )

        return data
    }

    private static func csvField(
        _ value: String
    ) -> String {
        /*
         RFC-style CSV escaping:
         - Double all embedded quotes.
         - Quote fields containing commas, quotes or line breaks.
         */

        let escaped = value.replacingOccurrences(
            of: "\"",
            with: "\"\""
        )

        let requiresQuotes =
            escaped.contains(",")
                || escaped.contains("\"")
                || escaped.contains("\n")
                || escaped.contains("\r")

        if requiresQuotes {
            return "\"\(escaped)\""
        }

        return escaped
    }

    // MARK: - JSON

    private static func jsonData(
        for devices: [Device]
    ) throws -> Data {
        let records = devices.map {
            ExportedDevice(device: $0)
        }

        let encoder = JSONEncoder()

        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes,
        ]

        return try encoder.encode(records)
    }

    // MARK: - File naming

    private static func defaultFileName(
        format: ExportFormat
    ) -> String {
        let formatter = DateFormatter()

        formatter.dateFormat =
            "yyyy-MM-dd-HHmmss"

        let timestamp = formatter.string(
            from: Date()
        )

        return "ipscanner-\(timestamp).\(format.fileExtension)"
    }

    private static func exportMessage(
        deviceCount: Int,
        format: ExportFormat
    ) -> String {
        let noun = deviceCount == 1
            ? "device"
            : "devices"

        return "Export \(deviceCount) \(noun) as \(format.displayName)."
    }

    // MARK: - Error handling

    private static func presentExportError(
        _ error: Error
    ) {
        let alert = NSAlert()

        alert.alertStyle = .critical
        alert.messageText =
            "The scan results could not be exported."

        alert.informativeText =
            error.localizedDescription

        alert.addButton(
            withTitle: "OK"
        )

        alert.runModal()
    }
}

// MARK: - Export representation

private struct ExportedDevice: Encodable {
    let hostname: String?
    let hostnameSource: String?
    let ipAddress: String
    let macAddress: String?
    let manufacturer: String?
    let openPorts: [UInt16]
    let openServices: [String]

    init(device: Device) {
        hostname = device.hostname

        hostnameSource =
            device.hostnameSource?.displayName

        ipAddress = device.ip
        macAddress = device.mac
        manufacturer = device.manufacturer

        openPorts = device.openPorts.sorted()

        openServices = openPorts.map {
            PortDatabase.name(for: $0)
                ?? "Unknown service"
        }
    }
}
