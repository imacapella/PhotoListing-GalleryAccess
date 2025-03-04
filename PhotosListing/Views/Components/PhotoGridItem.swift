import SwiftUI
import Photos

struct PhotoGridItem: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var fileSize: String = "..."
    @State private var isShowingPreview = false
    @GestureState private var isDetectingLongPress = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .onTapGesture {
                            isShowingPreview = true
                        }
                        .gesture(
                            LongPressGesture(minimumDuration: 0.2)
                                .updating($isDetectingLongPress) { currentState, gestureState, _ in
                                    gestureState = currentState
                                    if currentState {
                                        isShowingPreview = true
                                    }
                                }
                        )
                        .scaleEffect(isDetectingLongPress ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDetectingLongPress)
                } else {
                    ProgressView()
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .background(Color.gray.opacity(0.2))
                }
                
                HStack {
                    Text(fileSize)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            )
        }
        .padding(8)
        .onAppear {
            loadImage()
            calculateFileSize()
        }
        .sheet(isPresented: $isShowingPreview) {
            PhotoPreviewView(asset: asset)
        }
    }
    
    private func loadImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 300, height: 300),
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            image = result
        }
    }
    
    private func calculateFileSize() {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                let sizeOnDisk = Int64(unsignedInt64)
                DispatchQueue.main.async {
                    let mbSize = Double(sizeOnDisk) / (1024 * 1024)
                    fileSize = String(format: "%.1f MB", mbSize)
                }
            } else {
                let pixelSize = asset.pixelWidth * asset.pixelHeight
                let estimatedSize = Double(pixelSize) * 3 / (1024 * 1024)
                DispatchQueue.main.async {
                    fileSize = String(format: "~%.1f MB", estimatedSize)
                }
            }
        } else {
            fileSize = "Boyut bilinmiyor"
        }
    }
} 
