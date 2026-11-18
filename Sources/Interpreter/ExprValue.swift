// Tommy Han, 2026
//
// Represents the possible values of expressions in the interpreter.

public enum ExprValue: Equatable, CustomStringConvertible {
    case integer(Int)
    case string(String)

    public var description: String {
        switch self {
        case .integer(let value): return String(value)
        case .string(let value): return value
        }
    }
}
