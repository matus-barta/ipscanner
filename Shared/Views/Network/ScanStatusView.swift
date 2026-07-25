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
        #if os(macOS)
            macOSStatus
        #else
            iPadStatus
        #endif
    }

    private var macOSStatus: some View {
        VStack(alignment: .leading, spacing: 4) {
            Gauge(value: scanner.progress, in: 0.0 ... 1.0) {
                Text("Progress: \(progressPercentage)%")
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

    private var iPadStatus: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if scanner.isScanning {
                    ProgressView().controlSize(.small)

                    Text("Scanning").fontWeight(.medium)
                } else if scanner.scannedHosts > 0 {
                    Text("Complete").fontWeight(.medium)
                } else {
                    Text("Ready").foregroundStyle(.secondary)
                }

                Spacer()

                if scanner.totalHosts > 0 {
                    Text("\(scanner.scannedHosts) of \(scanner.totalHosts)")
                        .foregroundStyle(.secondary)

                    Text("\(scanner.onlineHosts) online")
                        .foregroundStyle(.secondary)

                    Text("\(progressPercentage)%")
                        .monospacedDigit().foregroundStyle(.secondary)
                }
            }

            ProgressView(value: scanner.progress, total: 1.0)
        }
        .font(.subheadline)
        .padding(.horizontal, 2)
    }

    private var progressPercentage: Int {
        Int(scanner.progress * 100)
    }
}
