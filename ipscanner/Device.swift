//
//  Device.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import Foundation

/// https://stackoverflow.com/questions/79666709/swiftdata-predicate-in-swift-6-language-mode
nonisolated struct Device: Identifiable, Hashable {
    let id = UUID()

    let ip: String

    var hostname: String?
    var mac: String?
    var manufacturer: String?

    var openPorts: Set<Int> = []

    var hostnameSort: String {
        hostname ?? ""
    }

    var macSort: String {
        mac ?? ""
    }

    var manufacturerSort: String {
        manufacturer ?? ""
    }
    
    var openPortsDisplay: String {
        openPorts
            .sorted()
            .map(String.init)
            .joined(separator: ", ")
    }

}
