// Tommy Han, 2026

enum TokenType {
    case instruction(OptCode)
    case integer(Int)
    case newline
    case eof
}

struct Token {
    let type: TokenType
    let line: Int
}
