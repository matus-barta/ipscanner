//
//  AppState.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
//  SPDX-License-Identifier: GPL-3.0-only
//  App Store exception: see APP_STORE_EXCEPTION.md.
//

import Observation

@MainActor
@Observable
final class AppState {
    var selectedDeviceID: Device.ID?
    var inspectorPresented = false
    var searchText = ""

    var searchPresented = false

    func toggleInspector() {
        inspectorPresented.toggle()
    }

    func focusSearch() {
        searchPresented = true
    }

    func clearSelection() {
        selectedDeviceID = nil
    }
}
