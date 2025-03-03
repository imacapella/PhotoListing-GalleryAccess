import SwiftUI
import Photos

struct PhotoGridItemView: View {
    let asset: PhotoAsset
    @StateObject private var imageLoader = ImageLoader()
    @State private var isShowingPreview = false
    @GestureState private var isDetectingLongPress = false
    
    var body: some View {
        GeometryReader { geometry in
            PhotoCardView(
                image: imageLoader.image,
                fileSize: imageLoader.fileSize,
                geometry: geometry,
                isDetectingLongPress: isDetectingLongPress
            )
            .onTapGesture { isShowingPreview = true }
            .gesture(longPressGesture)
        }
        .padding(8)
        .onAppear { imageLoader.load(asset: asset.asset) }
        .sheet(isPresented: $isShowingPreview) {
            PhotoPreviewView(asset: asset)
        }
    }
    
    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .updating($isDetectingLongPress) { currentState, gestureState, _ in
                gestureState = currentState
                if currentState {
                    isShowingPreview = true
                }
            }
    }
} 