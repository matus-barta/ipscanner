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

        HStack {
            TextField("", text: $scanner.subnets)
                .focused($subnetFieldFocused)
                .onChange(of: scanner.subnets) {
                    scanner.parseSubnets()
                }
                .onSubmit {
                    scanner.normalizeSubnetInput()
                }
            Button("Scan for subnets", systemImage: "arrow.trianglehead.clockwise.rotate.90",
                   action: scanner.refreshSubnets)
                .labelStyle(.iconOnly)
        }
    }
}
