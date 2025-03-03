//
//  ContentView.swift
//  PhotosListing
//
//  Created by Gürkan Karadaş on 26.02.2025.
//

import SwiftUI
import Photos
import QuickLook

struct ContentView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    @State private var showingFilterSheet = false
    @State private var selectedSortOption: SortOption = .date
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var gridColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
    
    enum SortOption {
        case date
        case size
        case name
    }
    
    var sortedAssets: [PHAsset] {
        switch selectedSortOption {
        case .date:
            return viewModel.assets.sorted { $0.creationDate ?? Date() > $1.creationDate ?? Date() }
        case .size:
            return viewModel.assets.sorted { $0.pixelWidth * $0.pixelHeight > $1.pixelWidth * $1.pixelHeight }
        case .name:
            return viewModel.assets.sorted { $0.localIdentifier < $1.localIdentifier }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 24) {
                    ForEach(sortedAssets, id: \.localIdentifier) { asset in
                        PhotoGridItem(asset: asset)
                            .aspectRatio(1, contentMode: .fit)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteAsset(asset)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Fotoğraflar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            isDarkMode.toggle()
                        } label: {
                            Label(
                                isDarkMode ? "Light Tema" : "Dark Tema",
                                systemImage: isDarkMode ? "sun.max.fill" : "moon.fill"
                            )
                        }
                        
                        Button {
                            viewModel.findAndRemoveDuplicates()
                        } label: {
                            Label("Duplicate Sil", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Sıralama", selection: $selectedSortOption) {
                            Label("Tarih", systemImage: "calendar").tag(SortOption.date)
                            Label("Boyut", systemImage: "photo").tag(SortOption.size)
                            Label("İsim", systemImage: "textformat").tag(SortOption.name)
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterView(viewModel: viewModel)
            }
            .onAppear {
                // Görünüm ilk yüklendiğinde kullanıcıdan izin isteyelim
                viewModel.requestAuthorization()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

struct PhotoGridItem: View {
    let asset: PHAsset
    @State private var image: UIImage?
    @State private var fileSize: String = "..."
    @State private var isShowingPreview = false
    @GestureState private var isDetectingLongPress = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Görsel
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
                
                // Dosya boyutu
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
            options.isNetworkAccessAllowed = true // iCloud'dan indirmeye izin ver
            
            // Önce dosya boyutunu almayı deneyelim
            if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                let sizeOnDisk = Int64(unsignedInt64)
                DispatchQueue.main.async {
                    let mbSize = Double(sizeOnDisk) / (1024 * 1024)
                    fileSize = String(format: "%.1f MB", mbSize)
                }
            } else {
                // Dosya boyutu alınamazsa piksel boyutundan tahmin edelim
                let pixelSize = asset.pixelWidth * asset.pixelHeight
                let estimatedSize = Double(pixelSize) * 3 / (1024 * 1024) // RGB için 3 byte/piksel
                DispatchQueue.main.async {
                    fileSize = String(format: "~%.1f MB", estimatedSize)
                }
            }
        } else {
            fileSize = "Boyut bilinmiyor"
        }
    }
}

struct PhotoPreviewView: View {
    let asset: PHAsset
    @Environment(\.dismiss) var dismiss
    @State private var previewImage: UIImage?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                if let image = previewImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ProgressView()
                }
            }
            .navigationBarItems(trailing: Button("Kapat") { dismiss() })
        }
        .onAppear {
            loadFullResolutionImage()
        }
    }
    
    private func loadFullResolutionImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            previewImage = result
        }
    }
}

struct FilterView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: PhotoLibraryViewModel
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var minimumSize: Double = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tarih Aralığı")) {
                    DatePicker("Başlangıç", selection: $startDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("Bitiş", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                
                Section(header: Text("Minimum Boyut (MB)")) {
                    VStack {
                        Slider(value: $minimumSize, in: 0...100, step: 1)
                        HStack {
                            Text("0 MB")
                            Spacer()
                            Text("\(Int(minimumSize)) MB")
                            Spacer()
                            Text("100 MB")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: {
                        viewModel.filterAssets(startDate: startDate, endDate: endDate, minimumSize: minimumSize)
                        dismiss()
                    }) {
                        HStack {
                            Spacer()
                            Text("Filtrele")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
    }
}

#Preview {
    ContentView()
}
