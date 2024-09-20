//
//  metronomeApp.swift
//  metronome Watch App
//
//  Created by 이영호 on 9/13/24.
//

import SwiftUI
import WatchKit

// Define your ExtensionDelegate
class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // Setup tasks after launching
    }
    // Implement other delegate methods as necessary
}

@main
struct metronome_Watch_AppApp: App {
    @WKExtensionDelegateAdaptor var appDelegate: ExtensionDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .backgroundTask(.appRefresh) { context in
            await withTaskCancellationHandler {
                // Handle the background refresh task.
            } onCancel: {
                // Clean up and prepare to become suspended.
            }
        }
    }
}
