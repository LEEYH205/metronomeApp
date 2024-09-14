//
//  metronomeApp.swift
//  metronome Watch App
//
//  Created by 이영호 on 9/13/24.
//

import SwiftUI

@main
struct metronome_Watch_AppApp: App {
    @WKExtensionDelegateAdaptor var appDelegate: ExtensionDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
