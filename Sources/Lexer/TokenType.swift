// Tommy Han, 2026

enum TokenType: Equatable {
    case instruction(OptCode)
    case integer(Int)
    case identifier(String)
    case fn
    case lparen  // "("
    case rparen  // ")"
    case colon   // ":"
    case comma   // ","
    case arrow   // "->"
    case newline
    case eof
}

struct Token {
    let type: TokenType
    let line: Int
}
