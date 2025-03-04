import SwiftUICore
import SwiftUI
import Photos

struct PhotoGridView: View {
    @ObservedObject var viewModel: PhotoLibraryViewModel
    let columns: [GridItem]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
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
    }
} 
