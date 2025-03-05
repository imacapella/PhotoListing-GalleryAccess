import SwiftUI
import Photos

struct PhotoGridItem: View {
    let asset: PHAsset
    let onDelete: () -> Void
    @State private var image: UIImage?
    @State private var fileSize: String = "..."
    @State private var isShowingPreview = false
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @State private var showDeleteAlert = false
    @AppStorage("hasConfirmedDeletion") private var hasConfirmedDeletion = false
    @State private var isScrolling = false
    @GestureState private var dragState = DragState.inactive
    
    enum DragState {
        case inactive
        case dragging(translation: CGFloat)
        
        var translation: CGFloat {
            switch self {
            case .inactive:
                return 0
            case .dragging(let translation):
                return translation
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack {
                ZStack(alignment: .bottom) {
                    imageContent(geometry: geometry)
                    
                    fileSizeIndicator
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                )
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .updating($dragState) { value, state, _ in
                            if abs(value.translation.height) < 30 {
                                state = .dragging(translation: value.translation.width)
                            }
                        }
                        .onChanged { gesture in
                            if abs(gesture.translation.height) < 30 {
                                let dragAmount = gesture.translation.width
                                if dragAmount < 0 {
                                    withAnimation(.interactiveSpring()) {
                                        offset = dragAmount
                                    }
                                }
                            }
                        }
                        .onEnded { gesture in
                            let dragAmount = gesture.translation.width
                            if dragAmount < -geometry.size.width / 3 && abs(gesture.translation.height) < 30 {
                                if hasConfirmedDeletion {
                                    withAnimation(.spring()) {
                                        offset = -geometry.size.width
                                        deleteWithAnimation()
                                    }
                                } else {
                                    withAnimation(.spring()) {
                                        showDeleteAlert = true
                                        offset = 0
                                    }
                                }
                            } else {
                                resetPosition()
                            }
                        }
                )
                
                if offset < -50 {
                    deleteIndicator
                }
            }
        }
        .padding(8)
        .alert("Fotoğrafı Sil", isPresented: $showDeleteAlert) {
            Button("Sil", role: .destructive) {
                hasConfirmedDeletion = true
                withAnimation(.spring()) {
                    offset = -UIScreen.main.bounds.width
                    deleteWithAnimation()
                }
            }
            Button("İptal", role: .cancel) {
                resetPosition()
            }
        } message: {
            Text("Bu fotoğrafı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.")
        }
        .onChange(of: showDeleteAlert) { newValue in
            if !newValue {
                resetPosition()
            }
        }
        .onAppear {
            loadImage()
            calculateFileSize()
        }
        .sheet(isPresented: $isShowingPreview) {
            PhotoPreviewView(asset: asset)
        }
    }
    
    private var deleteIndicator: some View {
        HStack {
            Image(systemName: "trash")
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(Color.red))
        }
        .transition(.opacity)
        .opacity(Double(abs(offset)) / 100)
    }
    
    private func imageContent(geometry: GeometryProxy) -> some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .onTapGesture {
                        isShowingPreview = true
                    }
            } else {
                ProgressView()
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .background(Color.gray.opacity(0.2))
            }
        }
    }
    
    private var fileSizeIndicator: some View {
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
    
    private func deleteWithAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            onDelete()
        }
    }
    
    private func loadImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 1024, height: 1024),
            contentMode: .aspectFill,
            options: options
        ) { result, info in
            DispatchQueue.main.async {
                if let image = result {
                    self.image = image
                }
            }
        }
    }
    
    private func calculateFileSize() {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first {
            if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                let sizeOnDisk = Int64(unsignedInt64)
                DispatchQueue.main.async {
                    let mbSize = Double(sizeOnDisk) / (1024 * 1024)
                    self.fileSize = String(format: "%.1f MB", mbSize)
                }
            } else {
                let pixelSize = asset.pixelWidth * asset.pixelHeight
                let estimatedSize = Double(pixelSize) * 3 / (1024 * 1024)
                DispatchQueue.main.async {
                    self.fileSize = String(format: "~%.1f MB", estimatedSize)
                }
            }
        } else {
            self.fileSize = "Boyut bilinmiyor"
        }
    }
    
    private func resetPosition() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            offset = 0
            isSwiped = false
        }
    }
} 
