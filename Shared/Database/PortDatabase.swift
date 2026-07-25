//
//  PortDatabase.swift
//  ipscanner
//
//  Created by Matúš Barta on 13/07/2026.
//

import Foundation

nonisolated enum PortDatabase {
    static let names: [UInt16: String] = [
        // Infrastructure
        53: "DNS",
        67: "DHCP",
        68: "DHCP",
        123: "NTP",
        161: "SNMP",

        // Administration
        21: "FTP",
        22: "SSH",
        23: "Telnet",
        3389: "RDP",
        5900: "VNC",

        // Web
        80: "HTTP",
        443: "HTTPS",
        8000: "HTTP Alt",
        8008: "Chromecast",
        8009: "Chromecast",
        8080: "HTTP Proxy",
        8081: "HTTP Alt",
        8443: "HTTPS Alt",

        // Windows
        135: "MS RPC",
        139: "NetBIOS",
        445: "SMB",

        // Mail
        25: "SMTP",
        110: "POP3",
        143: "IMAP",
        465: "SMTPS",
        587: "SMTP Submission",
        993: "IMAPS",
        995: "POP3S",

        // Directory
        389: "LDAP",
        636: "LDAPS",

        // Storage / NAS
        111: "RPC",
        548: "AFP",
        2049: "NFS",

        // Databases
        1433: "MSSQL",
        1521: "Oracle",
        3306: "MySQL",
        5432: "PostgreSQL",
        6379: "Redis",
        27017: "MongoDB",

        // Cameras
        554: "RTSP",
        8554: "RTSP Alt",

        // Printers
        515: "LPD",
        631: "IPP",
        9100: "JetDirect",

        // Android / Google
        5555: "ADB",

        // UPS
        3493: "NUT",

        // Virtualization
        902: "VMware Auth",
        903: "VMware Console",
        8006: "Proxmox",

        // Containers / Kubernetes
        2375: "Docker",
        2376: "Docker TLS",
        6443: "Kubernetes API",

        // Messaging / IoT
        1883: "MQTT",
        5672: "RabbitMQ",

        // Microsoft management
        5985: "WinRM",
        5986: "WinRM HTTPS",

        // Media
        32400: "Plex",

        // Discovery
        5353: "mDNS",
        1900: "SSDP",
    ]

    static func name(for port: UInt16) -> String? {
        names[port]
    }

    static func displayName(for port: UInt16) -> String {
        names[port] ?? "Port \(port)"
    }
}
