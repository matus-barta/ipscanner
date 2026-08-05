//
//  CopyableLabeledContent.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

struct CopyableLabeledContent: View {
    let title: String
    let value: String?
    let monospaced: Bool
    let unknownValue: String

    init(
        _ title: String,
        value: String?,
        monospaced: Bool = false,
        unknownValue: String = "Unknown"
    ) {
        self.title = title
        self.value = value
        self.monospaced = monospaced
        self.unknownValue = unknownValue
    }

    private var validValue: String? {
        guard let value else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedValue.isEmpty else {
            return nil
        }

        return trimmedValue
    }

    private var displayValue: String {
        validValue ?? unknownValue
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 6) {
                textValue

                Button(
                    "Copy \(title)",
                    systemImage: "doc.on.doc"
                ) {
                    guard let validValue else {
                        return
                    }

                    DeviceActions.copy(validValue)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .controlSize(.small)
                .disabled(validValue == nil)
                .help("Copy \(title)")
            }
        }
    }

    private var textValue: some View {
        Text(displayValue)
            .fontDesign(monospaced ? .monospaced : .default)
            .multilineTextAlignment(.trailing)
            .textSelection(.enabled)
            .foregroundStyle(.secondary)
    }
}
