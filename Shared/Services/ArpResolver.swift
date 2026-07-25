//
//  ArpResolver.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

nonisolated enum ArpResolver {
    static func macAddress(
        for ip: String
    ) -> String? {
        #if os(macOS)
            macOSMACAddress(for: ip)
        #else
            nil
        #endif
    }

    #if os(macOS)

        private static func macOSMACAddress(
            for ip: String
        ) -> String? {
            let process = Process()

            process.executableURL = URL(
                fileURLWithPath: "/usr/sbin/arp"
            )

            process.arguments = [
                "-n",
                ip,
            ]

            let pipe = Pipe()

            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                return nil
            }

            let data = pipe.fileHandleForReading
                .readDataToEndOfFile()

            guard let output = String(
                data: data,
                encoding: .utf8
            ) else {
                return nil
            }

            return parseMacAddress(
                from: output
            )
        }

        private static func parseMacAddress(
            from output: String
        ) -> String? {
            let pattern =
                #"([0-9a-fA-F]{1,2}:){5}[0-9a-fA-F]{1,2}"#

            guard let regex =
                try? NSRegularExpression(
                    pattern: pattern
                )
            else {
                return nil
            }

            let searchRange = NSRange(
                output.startIndex ..< output.endIndex,
                in: output
            )

            guard let match = regex.firstMatch(
                in: output,
                range: searchRange
            ),
                let macRange = Range(
                    match.range,
                    in: output
                )
            else {
                return nil
            }

            return String(output[macRange])
        }

    #endif
}
