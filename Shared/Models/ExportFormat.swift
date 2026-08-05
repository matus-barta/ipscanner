//
//  ExportFormat.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Foundation
import UniformTypeIdentifiers

nonisolated enum ExportFormat:
    String,
    CaseIterable,
    Identifiable,
    Sendable
{
    case csv
    case json

    var id: Self {
        self
    }

    var displayName: String {
        switch self {
        case .csv:
            "CSV"

        case .json:
            "JSON"
        }
    }

    var fileExtension: String {
        rawValue
    }

    var contentType: UTType {
        switch self {
        case .csv:
            .commaSeparatedText

        case .json:
            .json
        }
    }

    var systemImage: String {
        switch self {
        case .csv:
            "tablecells"

        case .json:
            "curlybraces"
        }
    }
}
