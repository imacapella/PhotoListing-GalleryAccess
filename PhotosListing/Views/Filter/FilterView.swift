import SwiftUI
import Photos

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
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Text("Filtrele")
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Filtreler")
            .navigationBarItems(trailing: Button("Kapat") {
                dismiss()
            })
        }
    }
} 