//
//  ContentView.swift
//  PhotosListing
//
//  Created by Gürkan Karadaş on 26.02.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PhotoLibraryViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                    PhotoRow(asset: asset)
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.deleteAsset(asset)
                            } label: {
                                Text("Sil")
                            }
                        }
                }
            }
            .navigationTitle("Fotoğraflar")
            .onAppear {
                // Görünüm ilk yüklendiğinde kullanıcıdan izin isteyelim
                viewModel.requestAuthorization()
            }
        }
    }
}


#Preview {
    ContentView()
}
