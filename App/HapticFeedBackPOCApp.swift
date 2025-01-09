//
//  HapticFeedBackPOCApp.swift
//  HapticFeedBackPOC
//
//

import SwiftUI

@main
struct HapticFeedBackPOCApp: App {
    
    @ObservedObject var hapticManager = HapticManager()
    @State private var engineStarted = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if !engineStarted {
                        hapticManager.createEngine {
                            engineStarted = true
                        }
                    }
                }
        }
    }
}
