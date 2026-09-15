// Tommy Han, 2026

enum TokenType: Equatable {
    case instruction(OptCode)
    case integer(Int)
    case identifier(String)
    case funKeyword
    case type(ValueType)
    case colon  // ":"
    case arrow  // "->"
    case lparen  // "("
    case rparen  // ")"
    case leftBrace
    case rightBrace
    case comma
    case newline
    case eof
}

struct Token {
    let type: TokenType
    let line: Int
}
