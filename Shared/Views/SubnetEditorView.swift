//
//  SubnetEditorView.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

struct SubnetEditorView: View {
    @Environment(Scanner.self) private var scanner

    @FocusState.Binding var subnetFieldFocused: Bool

    var body: some View {
        @Bindable var scanner = scanner

        HStack(spacing: 8) {
            #if os(macOS)
                InterfaceSelectorView()
            #endif
            #if os(iOS)
                Image(systemName: "network")
                    .foregroundStyle(.secondary)
            #endif
            TextField(
                "Subnets",
                text: $scanner.subnets
            )
            .focused($subnetFieldFocused)
            .onChange(of: scanner.subnets) {
                scanner.parseSubnets()
            }
            .onSubmit {
                scanner.normalizeSubnetInput()
            }

            #if os(iOS)
            .textFieldStyle(.plain)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(.numbersAndPunctuation)
            #endif

            #if os(iOS)
                Divider()
                    .frame(height: 22)
            #endif

            Button(
                "Refresh Interfaces",
                systemImage:
                "arrow.trianglehead.clockwise.rotate.90"
            ) {
                scanner.refreshInterfaces()
            }
            .labelStyle(.iconOnly)
            .help("Refresh network interfaces")
        }
        #if os(iOS)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.background)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    subnetFieldFocused ? Color.accentColor : Color.secondary.opacity(0.3),
                    lineWidth: subnetFieldFocused ? 2 : 1
                )
        }
        .contentShape(
            RoundedRectangle(cornerRadius: 10)
        )
        .onTapGesture {
            subnetFieldFocused = true
        }
        #endif
    }
}
