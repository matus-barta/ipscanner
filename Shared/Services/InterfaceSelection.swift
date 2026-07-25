//
//  InterfaceSelection.swift
//  ipscanner
//

import Foundation
import Observation

@MainActor
@Observable
final class InterfaceSelection {
    private(set) var availableInterfaces: [NetworkInterface] = []
    private(set) var selectedInterfaceIDs: Set<NetworkInterface.ID> = []

    var physicalInterfacesOnly = true

    @ObservationIgnored
    var onSelectionChanged: (([Subnet]) -> Void)?

    var selectedCount: Int {
        selectedInterfaceIDs.count
    }

    var selectedInterfaces: [NetworkInterface] {
        availableInterfaces.filter {
            selectedInterfaceIDs.contains($0.id)
        }
    }

    var selectedSubnets: [Subnet] {
        let subnets: [Subnet] = selectedInterfaces.compactMap {
            interface -> Subnet? in
            guard let network = interface.networkAddress else {
                return nil
            }

            return Subnet(
                network: network,
                prefix: interface.cidrPrefix
            )
        }

        return Array(Set(subnets))
            .sorted {
                $0.displayValue.localizedStandardCompare(
                    $1.displayValue
                ) == .orderedAscending
            }
    }

    func refresh() {
        let previousSelection = selectedInterfaceIDs

        availableInterfaces = NetworkInterfaces.getAll()
            .sorted {
                if $0.name == $1.name {
                    return $0.address.localizedStandardCompare(
                        $1.address
                    ) == .orderedAscending
                }

                return $0.name.localizedStandardCompare(
                    $1.name
                ) == .orderedAscending
            }

        if physicalInterfacesOnly {
            selectPhysicalInterfaces(notify: false)
        } else {
            restoreSelection(
                previousSelection,
                notify: false
            )
        }

        notifySelectionChanged()
    }

    func isSelected(
        _ interface: NetworkInterface
    ) -> Bool {
        selectedInterfaceIDs.contains(interface.id)
    }

    func setSelected(
        _ interface: NetworkInterface,
        selected: Bool
    ) {
        if selected {
            selectedInterfaceIDs.insert(interface.id)
        } else {
            selectedInterfaceIDs.remove(interface.id)
        }

        // The user has made a custom selection.
        physicalInterfacesOnly = false

        notifySelectionChanged()
    }

    func setPhysicalInterfacesOnly(
        _ enabled: Bool
    ) {
        physicalInterfacesOnly = enabled

        if enabled {
            selectPhysicalInterfaces(notify: false)
        }

        /*
         Disabling automatic physical selection preserves the current
         selection. The user can then manually add VPN, bridge, tunnel,
         or other interfaces.
         */

        notifySelectionChanged()
    }

    func selectAll() {
        physicalInterfacesOnly = false

        selectedInterfaceIDs = Set(
            availableInterfaces.map(\.id)
        )

        notifySelectionChanged()
    }

    func deselectAll() {
        physicalInterfacesOnly = false
        selectedInterfaceIDs.removeAll()

        notifySelectionChanged()
    }

    private func selectPhysicalInterfaces(
        notify: Bool
    ) {
        selectedInterfaceIDs = Set(
            availableInterfaces
                .filter(\.isPhysical)
                .map(\.id)
        )

        if notify {
            notifySelectionChanged()
        }
    }

    private func restoreSelection(
        _ previousSelection: Set<NetworkInterface.ID>,
        notify: Bool
    ) {
        let availableIDs = Set(
            availableInterfaces.map(\.id)
        )

        selectedInterfaceIDs = previousSelection
            .intersection(availableIDs)

        if notify {
            notifySelectionChanged()
        }
    }

    private func notifySelectionChanged() {
        onSelectionChanged?(selectedSubnets)
    }
}
