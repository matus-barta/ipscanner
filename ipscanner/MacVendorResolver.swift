//
//  MacVendorResolver.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

nonisolated enum MacVendorResolver {
    private static let vendors: [UInt32: String] = loadDatabase()

    static func vendor(for mac: String?) -> String? {
        guard let mac else {
            return nil
        }

        guard let oui = ouiPrefix(from: mac) else {
            return nil
        }

        return vendors[oui]
    }

    private static func ouiPrefix(from mac: String) -> UInt32? {
        let normalized = mac
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: ".", with: "")
            .uppercased()

        guard normalized.count >= 6 else {
            return nil
        }

        let prefix = String(normalized.prefix(6))

        return UInt32(prefix, radix: 16)
    }

    private static func loadDatabase() -> [UInt32: String] {
        guard let url = Bundle.main.url(
            forResource: "oui-min",
            withExtension: "tsv"
        ) else {
            print("OUI database not found")
            return [:]
        }

        guard let content = try? String(
            contentsOf: url,
            encoding: .utf8
        ) else {
            print("Could not read OUI database")
            return [:]
        }

        var result: [UInt32: String] = [:]

        for line in content.split(whereSeparator: \.isNewline) {
            let parts = line.split(
                separator: "\t",
                maxSplits: 1
            )

            guard parts.count == 2 else {
                continue
            }

            let ouiString = String(parts[0])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()

            let vendor = String(parts[1])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard let oui = UInt32(ouiString, radix: 16),
                  !vendor.isEmpty
            else {
                continue
            }

            result[oui] = vendor
        }

        print("Loaded \(result.count) OUI vendors")

        return result
    }
}
