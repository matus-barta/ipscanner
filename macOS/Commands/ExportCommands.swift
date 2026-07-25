//
//  ExportCommands.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//

import SwiftUI

struct ExportCommands: Commands {
    let scanner: Scanner

    var body: some Commands {
        CommandGroup(
            before: .saveItem
        ) {
            Menu(
                "Export as…",
                systemImage: "square.and.arrow.up.on.square"
            ) {
                Button(
                    "Export as CSV…",
                    systemImage: "tablecells"
                ) {
                    scanner.exportDevices(
                        as: .csv
                    )
                }
                .keyboardShortcut(
                    "e",
                    modifiers: [
                        .command,
                        .shift,
                    ]
                )

                Button(
                    "Export as JSON…",
                    systemImage: "curlybraces"
                ) {
                    scanner.exportDevices(
                        as: .json
                    )
                }
            }
            .disabled(scanner.devices.isEmpty)
        }
    }
}
