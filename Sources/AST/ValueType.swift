// Tommy Han, 2026

enum ValueType: Equatable {
    case int

    var name: String {
        switch self {
        case .int: return "int"
        }
    }
}
