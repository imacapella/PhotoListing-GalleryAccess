//
//  ListView.swift
//  PhotosListing
//
//  Created by Gürkan Karadaş on 26.02.2025.
//

import SwiftUI
import Photos

/*class PhotoLibraryViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    
    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized, .limited:
                self.fetchAssets()
            default:
                print("Erişim izni verilmedi veya reddedildi.")
            }
        }
    }
    
    func fetchAssets() {
        let fetchOptions = PHFetchOptions()
        // Örneğin, en yeni fotoğraflar en üstte gelsin:
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        // Sadece fotoğrafları çekmek için:
        let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        var fetchedAssets = [PHAsset]()
        result.enumerateObjects { asset, _, _ in
            fetchedAssets.append(asset)
        }
        
        DispatchQueue.main.async {
            self.assets = fetchedAssets
        }
    }
    
    func deleteAsset(_ asset: PHAsset) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
        }) { success, error in
            if success {
                // Başarılı silme işlemi sonrası listeden çıkaralım
                DispatchQueue.main.async {
                    self.assets.removeAll { $0.localIdentifier == asset.localIdentifier }
                }
            } else {
                print("Silme hatası: \(error?.localizedDescription ?? "")")
            }
        }
    }
}*/


struct PhotoRow: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipped()
            } else {
                Color.gray
                    .frame(width: 80, height: 80)
            }

            // Basitçe asset'ın localIdentifier'ını veya başka bilgileri gösterebilirsiniz
            Text("Asset: \(asset.localIdentifier)")
                .font(.caption)
                .lineLimit(1)
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        
        // Thumbnail boyutunda bir görsel alalım
        let targetSize = CGSize(width: 200, height: 200)
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, info in
            self.image = result
        }
    }
}


/*#Preview {
    ListView()
}*/
