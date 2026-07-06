// Tommy Han, 2026

enum TokenType {
    case instruction(OptCode)
    case integer
    case newline
    case eof
}

struct Token {
    let type: TokenType
    let line: Int
}
