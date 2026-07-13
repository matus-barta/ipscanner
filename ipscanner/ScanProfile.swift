//
//  ScanProfile.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

enum ScanProfile: String, CaseIterable, Identifiable {
    case quick
    case standard
    case deep

    var id: Self {
        self
    }

    var displayName: String {
        switch self {
        case .quick:
            "Quick"

        case .standard:
            "Standard"

        case .deep:
            "Deep"
        }
    }

    var ports: [UInt16] {
        switch self {
        case .quick:
            [
                22, // SSH
                80, // HTTP
                443, // HTTPS
                445, // SMB
                3389, // RDP
            ]

        case .standard:
            [
                // Infrastructure
                53,
                123,
                161,

                // Administration
                21,
                22,
                23,

                // Web
                80,
                443,
                8000,
                8008,
                8009,
                8080,
                8443,

                // Windows
                135,
                139,
                445,
                3389,

                // Mail
                25,
                110,
                143,
                465,
                587,
                993,
                995,

                // Directory
                389,
                636,

                // Storage / NAS
                111,
                548,
                2049,

                // Databases
                1433,
                1521,
                3306,
                5432,
                6379,

                // Cameras
                554,
                8554,

                // Printers
                515,
                631,
                9100,

                // Android
                5555,

                // UPS
                3493,

                // Virtualization
                902,
                903,
                8006,
            ]

        case .deep:
            [
                20, 21, 22, 23, 25, 53, 67, 68, 69, 80,
                88, 110, 111, 119, 123, 135, 137, 138, 139, 143,
                161, 162, 179, 389, 427, 443, 445, 465, 500, 514,
                515, 520, 548, 554, 587, 631, 636, 873, 902, 903,
                989, 990, 993, 995, 1080, 1194, 1433, 1434, 1521, 1723,
                1812, 1813, 1883, 1900, 2049, 2082, 2083, 2222, 2375, 2376,
                25565, 3128, 3268, 3269, 3306, 3389, 3493, 4444, 4500, 5000,
                5001, 5060, 5061, 5222, 5353, 5432, 5555, 5601, 5672, 5683,
                5900, 5985, 5986, 6379, 6443, 6667, 6881, 7001, 7002, 7443,
                7777, 8000, 8006, 8008, 8009, 8080, 8081, 8086, 8096, 8123,
                8443, 8554, 8888, 9000, 9090, 9100, 9200, 9300, 9418, 9999,
                10000, 11211, 15672, 16992, 16993,
                27017, 27018, 27019, 32400,
            ]
        }
    }
}
