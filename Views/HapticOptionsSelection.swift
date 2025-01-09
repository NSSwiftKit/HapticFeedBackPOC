//
//  HapticOptionsSelection.swift
//  HapticFeedBackPOC
//
//


import SwiftUI
import AVKit
import MobileCoreServices
import AVFoundation
import CoreHaptics
import UIKit
import SDWebImageSwiftUI

extension Notification.Name {
    static let videoDidFinishPlaying = Notification.Name("VideoDidFinishPlaying")
}

class PlayerObserver: NSObject {
    private var player: AVPlayer?
    
    func startObserving(player: AVPlayer) {
        self.player = player
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerDidFinishPlaying),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: player.currentItem)
    }
    
    func stopObserving() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
        player = nil
    }
    
    @objc func playerDidFinishPlaying() {
        NotificationCenter.default.post(name: .videoDidFinishPlaying, object: nil)
    }
}

struct HapticOptionsSelection: View {
    
    @State private var player = AVPlayer()
    @ObservedObject var hapticManager = HapticManager()
    let playerObserver = PlayerObserver()
    @State private var navigateToVideo = false
    @State private var isHapticPlaying = false
    @State private var timer: Timer?
    @State private var showGifPicker =  false
    @State private var showPicker = false // Flag to control showing the image picker
    @State private var showActionAlert = false // Flag to control showing the action alert
    @State private var showDocumentPickerAlert = false // Flag to control showing the document picker alert
    @State private var isShowingFileBrowser = false
    @State private var selectedVideoUrl: URL?
    @State private var hapticPatern: CHHapticPattern?
    
    var body: some View {
        // below Vstack is for open file browser to select ahap file
        NavigationStack {
            
            VStack{
                
            }.fileImporter(isPresented: $isShowingFileBrowser, allowedContentTypes: [.json], allowsMultipleSelection: false, onCompletion: { results in
                switch results {
                case .success(let fileurls):
                    for fileurl in fileurls {
                        print(fileurl.path)
                        // get read access
                        if fileurl.startAccessingSecurityScopedResource(){
                            do {
                                //patern generated from ahap file
                                hapticPatern = try CHHapticPattern(contentsOf: fileurl)
                                
                                //function call for playing both haptic and video
                                playHapticAndVideo(videoUrl: selectedVideoUrl, hapticPatern: hapticPatern!)
                            }catch {
                                print("An error occurred playing haptic: \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    print(error)
                }
                
            })//below alert for gallery
            .alert(isPresented: $showDocumentPickerAlert) {
                Alert(title: Text("Open Document Picker?"), message: Text("Would you like to open the document picker to select an AHAP file?"), primaryButton: .default(Text("Open")) {
                    // Add action to open document picker
                    isShowingFileBrowser = true
                }, secondaryButton: .cancel())
            }
            VStack {
                //for playing video
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .navigationBarBackButtonHidden()
                    .onDisappear {
                        player.pause()
                        timer?.invalidate()
                        playerObserver.stopObserving()
                        player.pause()
                        hapticManager.stopHapticLoop()
                        isHapticPlaying = false
                    }
                    .sheet(isPresented: $showPicker, onDismiss: nil) {
                        ImagePicker(sourceType: .savedPhotosAlbum, mediaTypes: [kUTTypeMovie as String], completionHandler: { url in
                            showDocumentPickerAlert = true
                            selectedVideoUrl = url
                        })
                    }
                
                NavigationLink(
                    destination: ContentView(),
                    isActive: $navigateToVideo
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .onReceive(NotificationCenter.default.publisher(for: .videoDidFinishPlaying)) { _ in
                if isHapticPlaying {
                    hapticManager.stopHapticLoop()
                    isHapticPlaying = false
//                    showActionAlert = true
                   navigateToVideo = true

                }
            }.onReceive(player.publisher(for: \.rate)) { rate in
                if rate != 0.0 && !isHapticPlaying {
                    // Start playing haptic feedback again
                    if let videoUrl = selectedVideoUrl, let pattern = hapticPatern {
                        
                        playHapticAndVideo(videoUrl: videoUrl, hapticPatern: pattern)
                        
                    }
                }
            }
            .alert(isPresented: $showActionAlert) {
                Alert(title: Text("Open Gallery?"), message: Text("Would you like to open the gallery to select a video?"), primaryButton: .default(Text("Open")) {
                    showPicker = true
                }, secondaryButton: .cancel())
            }
            .onAppear {
                player.play()
                showActionAlert = true
            }
            
        }
    }
    func playHapticAndVideo(videoUrl:URL?, hapticPatern: CHHapticPattern ) {
        if let url = videoUrl {
            player = AVPlayer(url: url)
            playerObserver.startObserving(player: player)
            player.play()
            hapticManager.startHapticLoopWithCustomFile(path: hapticPatern)
            isHapticPlaying = true
        }
    }
   
}

struct HapticOptionsSelection_Previews: PreviewProvider {
    static var previews: some View {
        HapticOptionsSelection()
    }
}
