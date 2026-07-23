//
//  SccanStatusView.swift
//  ipscanner
//
//  Created by Matus Barta on 18/07/2026.
//
import SwiftUI

struct ScanStatusView: View {
    @Environment(Scanner.self) private var scanner

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Gauge(value: scanner.progress, in: 0.0 ... 1.0) {
                Text("Progress: \(Int(scanner.progress * 100))%")
            } currentValueLabel: {
                HStack {
                    Text("Scanned: \(scanner.scannedHosts)/\(scanner.totalHosts)")
                    Spacer()
                    Text("Online: \(scanner.onlineHosts)")
                    Text("Offline: \(scanner.offlineHosts)")
                }
            }.gaugeStyle(
                .accessoryLinearCapacity
            )
        }
    }
}
