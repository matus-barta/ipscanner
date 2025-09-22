//
//  Device.swift
//  ipscanner
//
//  Created by Matúš Barta on 18/09/2025.
//

import Foundation

struct Device : Identifiable, Hashable{
    var id = UUID()
    
    let ip: String
    let mac: String
    let manufacturer: String
    let name: String
    
}
