//
//  SubnetEditorView.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//
import SwiftUI

struct SubnetEditorView: View {
    @Environment(Scanner.self) private var scanner

    @FocusState.Binding var subnetFieldFocused: Bool

    var body: some View {
        @Bindable var scanner = scanner

        HStack(spacing: 8) {
            InterfaceSelectorView()

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
    }
}
