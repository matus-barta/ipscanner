//
//  Scanner+Subnets.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//
import Foundation

@MainActor
extension Scanner {
    func configureInterfaceSelection(
        physicalOnly: Bool
    ) {
        interfaceSelection.onSelectionChanged = {
            [weak self] selectedSubnets in
            self?.applySelectedSubnets(
                selectedSubnets
            )
        }

        interfaceSelection.setPhysicalInterfacesOnly(
            physicalOnly
        )

        interfaceSelection.refresh()
    }

    func parseSubnets() {
        subnetList = parsedSubnets(
            from: subnets
        )
    }

    func normalizeSubnetInput() {
        let normalized = normalizedSubnets(
            parsedSubnets(from: subnets)
        )

        subnetList = normalized
        subnets = subnetText(from: normalized)
    }

    func applySelectedSubnets(
        _ selectedSubnets: [Subnet]
    ) {
        let normalized = normalizedSubnets(
            selectedSubnets
        )

        subnetList = normalized
        subnets = subnetText(from: normalized)
    }

    func uniqueHosts() -> [String] {
        Array(
            Set(
                subnetList.flatMap {
                    $0.hosts()
                }
            )
        )
        .sorted {
            ipSortable($0) < ipSortable($1)
        }
    }

    private func parsedSubnets(
        from input: String
    ) -> [Subnet] {
        input
            .split(separator: ",")
            .compactMap {
                Subnet.parse(
                    String($0)
                )
            }
    }

    private func normalizedSubnets(
        _ values: [Subnet]
    ) -> [Subnet] {
        Array(Set(values))
            .sorted {
                $0.displayValue.localizedStandardCompare(
                    $1.displayValue
                ) == .orderedAscending
            }
    }

    private func subnetText(
        from values: [Subnet]
    ) -> String {
        values
            .map(\.displayValue)
            .joined(separator: ", ")
    }

    private func ipSortable(
        _ address: String
    ) -> UInt32 {
        let octets = address
            .split(separator: ".")
            .compactMap {
                UInt32($0)
            }

        guard octets.count == 4 else {
            return 0
        }

        return (octets[0] << 24)
            | (octets[1] << 16)
            | (octets[2] << 8)
            | octets[3]
    }
}
