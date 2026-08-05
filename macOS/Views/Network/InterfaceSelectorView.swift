//
//  InterfaceSelectorView.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import SwiftUI

struct InterfaceSelectorView: View {
    @Environment(Scanner.self) private var scanner

    private var interfaces: InterfaceSelection {
        scanner.interfaceSelection
    }

    var body: some View {
        Menu {
            Toggle(
                "Physical interfaces only",
                isOn: physicalInterfacesOnlyBinding
            )

            Divider()

            if interfaces.availableInterfaces.isEmpty {
                Text("No active IPv4 interfaces")
            } else {
                ForEach(
                    interfaces.availableInterfaces
                ) { interface in
                    Toggle(
                        isOn: interfaceBinding(interface)
                    ) {
                        Label(
                            interface.displayName,
                            systemImage: interface.type.systemImage
                        )
                    }
                }
            }

            Divider()

            Button("Select All") {
                interfaces.selectAll()
            }

            Button("Deselect All") {
                interfaces.deselectAll()
            }

            Divider()

            Button(
                "Refresh Interfaces",
                systemImage: "arrow.clockwise"
            ) {
                interfaces.refresh()
            }
        } label: {
            Label(
                selectorTitle,
                systemImage: "network"
            )
        }
        .help("Select network interfaces")
    }

    private var physicalInterfacesOnlyBinding: Binding<Bool> {
        Binding(
            get: {
                interfaces.physicalInterfacesOnly
            },
            set: { enabled in
                interfaces.setPhysicalInterfacesOnly(enabled)
            }
        )
    }

    private func interfaceBinding(
        _ interface: NetworkInterface
    ) -> Binding<Bool> {
        Binding(
            get: {
                interfaces.isSelected(interface)
            },
            set: { selected in
                interfaces.setSelected(
                    interface,
                    selected: selected
                )
            }
        )
    }

    private var selectorTitle: String {
        switch interfaces.selectedCount {
        case 0:
            "No Interfaces"

        case 1:
            "1 Interface"

        default:
            "\(interfaces.selectedCount) Interfaces"
        }
    }
}

#Preview {
    InterfaceSelectorView()
        .padding()
        .environment(Scanner())
}
