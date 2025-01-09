//
//  HapticManager.swift
//  HapticFeedBackPOC
//

import SwiftUI
import CoreHaptics

class HapticManager: ObservableObject {
    static var engine: CHHapticEngine?
    var player: CHHapticPatternPlayer?
//    var timer: Timer?
    
    func createEngine(completion: @escaping () -> Void) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Device does not support haptics")
            return
        }
        
        do {
            HapticManager.engine = try CHHapticEngine()
            HapticManager.engine?.playsHapticsOnly = true
            try HapticManager.engine?.start(completionHandler: { error in
                if let error = error {
                    print("Haptic engine failed to start: \(error)")
                } else {
                    print("Haptic engine started successfully")
                    completion()
                }
            })
        } catch let error {
            print("Error creating haptic engine: \(error)")
        }
    }
    
    func startHapticLoop() {
        guard let engine = HapticManager.engine else {
            print("Haptic engine is not initialized")
            return
        }
        
        do {
            // Start the haptic feedback loop
            try engine.start()
            let path = Bundle.main.url(forResource: "Inflate", withExtension: "ahap")!
            let pattern = try CHHapticPattern(contentsOf: path)
            player = try engine.makePlayer(with: pattern)
            
            // Start the haptic player
            try player?.start(atTime: CHHapticTimeImmediate)
            
            // Schedule a Timer to restart the player when it completes its cycle
//            timer = Timer.scheduledTimer(withTimeInterval: pattern.duration, repeats: true) { _ in
                do {
                    // Restart the haptic player
                    try self.player?.start(atTime: CHHapticTimeImmediate)
                } catch {
                    print("An error occurred playing haptic: \(error)")
                }
//            }
        } catch {
            print("An error occurred playing haptic: \(error)")
        }
    }
    
    func startHapticLoopWithCustomFile(path: CHHapticPattern) {
        guard let engine = HapticManager.engine else {
            print("Haptic engine is not initialized")
            return
        }
        
        do {
            // Start the haptic feedback loop
            try engine.start()
            
            let pattern = path
            player = try engine.makePlayer(with: pattern)
            
            // Start the haptic player
            try player?.start(atTime: CHHapticTimeImmediate)
            
            // Schedule a Timer to restart the player when it completes its cycle
//            timer = Timer.scheduledTimer(withTimeInterval: pattern.duration, repeats: true) { _ in
                do {
                    // Restart the haptic player
                    try self.player?.start(atTime: CHHapticTimeImmediate)
                } catch {
                    print("An error occurred playing haptic: \(error)")
                }
//            }
        } catch {
            print("An error occurred playing haptic: \(error)")
        }
    }
    
    
    func stopHapticLoop() {
        // Stop the haptic feedback loop
//        timer?.invalidate()
        do {
            try player?.stop(atTime: CHHapticTimeImmediate)
            
        }catch {
            
        }
    }
}
