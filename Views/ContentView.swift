//
//  ContentView.swift
//  HapticFeedBackPOC
//

import SwiftUI
import CoreHaptics
import SDWebImageSwiftUI
//import Kingfisher

struct ContentView: View {
    
    @State private var navigateToVideo = false
    @State private var isHapticPlaying = false
    @ObservedObject var hapticManager = HapticManager()
    @State private var engineStarted = false
    @State private var showActionGifAlert = false
    @State private var showPicker = false
    @State private var showDocumentPickerAlert = false
    @State private var isShowingFileBrowser = false
    @State private var selectedGifUrl: URL?
    @State private var tempGifUrl: URL?
    @State private var hapticPatern: CHHapticPattern?
    
    @State private var numberOfFrames = 0
    @State private var totalDuration: TimeInterval = 0.0
    @State private var currentImageIndex = 0
    @State private var animationCompleted = false
    
    var body: some View {
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
                                playHaptic( hapticPatern: hapticPatern!)
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
                WebImage(url: selectedGifUrl)
                    .onSuccess { _,_,_  in
                        if selectedGifUrl != nil {
                            let gifData = try? Data(contentsOf: selectedGifUrl!)
                            if let gifSource = CGImageSourceCreateWithData(gifData as! CFData, nil) {
                                // Count the number of frames
                                numberOfFrames = CGImageSourceGetCount(gifSource)
                                
                                // Calculate the total duration
                                totalDuration = 0.0
                                for i in 0..<numberOfFrames {
                                    if let frameProperties = CGImageSourceCopyPropertiesAtIndex(gifSource, i, nil) as? [String: Any],
                                       let gifProperties = frameProperties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                                       let frameDuration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval {
                                        totalDuration += frameDuration
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration - 0.5) {
                                    navigateToVideo = true
                                }
                            }
                        }
                    }
                    .resizable()
                    .frame(width: 200, height: 200)
                    .fileImporter(isPresented: $showPicker, allowedContentTypes: [.gif], allowsMultipleSelection: false, onCompletion: { results in
                        switch results {
                        case .success(let fileurls):
                            for fileurl in fileurls {
                                print(fileurl.path)
                                // get read access
                                if fileurl.startAccessingSecurityScopedResource(){
                                    tempGifUrl = fileurl
                                    showDocumentPickerAlert = true
                                }
                            }
                        case .failure(let error):
                            print(error)
                        }
                        
                    })
                
                NavigationLink(
                    destination: HapticOptionsSelection(),
                    isActive: $navigateToVideo
                ) {
                    EmptyView()
                }
                .hidden()
            }.alert(isPresented: $showActionGifAlert) {
                Alert(title: Text("Open Gallery?"), message: Text("Would you like to open the gallery to select a gif?"), primaryButton: .default(Text("Open")) {
                    showPicker = true
                }, secondaryButton: .cancel())
            }
            .onAppear {
                // Start playing haptic loop when view appears
                showActionGifAlert = true
            }
        }
    }
    func playHaptic( hapticPatern: CHHapticPattern ) {
        selectedGifUrl = tempGifUrl
        hapticManager.startHapticLoopWithCustomFile(path: hapticPatern)
        isHapticPlaying = true
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
