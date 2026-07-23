//
//  AppState.swift
//  ipscanner
//
//  Created by Matúš Barta on 23/07/2026.
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
