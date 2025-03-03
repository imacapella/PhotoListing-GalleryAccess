import Foundation

enum SortOption: String, CaseIterable, Identifiable, Hashable {
    case date = "Tarih"
    case size = "Boyut"
    case name = "İsim"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .date: return "calendar"
        case .size: return "photo"
        case .name: return "textformat"
        }
    }
} 