// Tommy Han, 2026

enum ValueType: Equatable {
    case int
    case string

    var name: String {
        switch self {
        case .int: return "int"
        case .string: return "string"
        }
    }
}
