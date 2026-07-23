//
//  Scanner+Export.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//
import Foundation

@MainActor
extension Scanner {
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
        DeviceExporter.export(
            [device],
            format: format,
            suggestedFileName: exportFileName(
                for: device,
                format: format
            )
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
}
