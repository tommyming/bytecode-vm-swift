class Parser {
    private let tokens: [Token]
    private var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    /// Parse the token stream into an AST. Returns the root expression.
    func parse() -> Expr {
        current = 0
        return expression()
    }

    // MARK: - Parser Grammar Rules

    // expression -> term ( ( "+" | "-" ) term )*
    private func expression() -> Expr {
        var expr = term()

        while match(.instruction(.add)) || match(.instruction(.minus)) {
            let operatorToken = previous()
            let right = term()

            // Build a left-associative tree: ((a + b) + c)
            expr = .binary(
                op: opCode(from: operatorToken),
                left: expr,
                right: right
            )
        }
        return expr
    }

    // term -> factor ( ( "*" | "/" ) factor )*
    private func term() -> Expr {
        var expr = factor()

        while match(.instruction(.multiply)) || match(.instruction(.divide)) {
            let operatorToken = previous()
            let right = factor()

            expr = .binary(
                op: opCode(from: operatorToken),
                left: expr,
                right: right
            )
        }
        return expr
    }

    // factor -> integer
    private func factor() -> Expr {
        if matchInteger() {
            if case .integer(let value) = previous().type {
                return .number(value)
            }
        }
        fatalError("Parser Error: Expected a number on line \(peek().line)")
    }

    // MARK: - Helpers

    /// Map a binary operator token to its OptCode.
    private func opCode(from token: Token) -> OptCode {
        switch token.type {
        case .instruction(let op): return op
        default: fatalError("Parser Error: Expected an operator token, got \(token.type)")
        }
    }

    private func match(_ type: TokenType) -> Bool {
        if check(type) {
            _ = advance()
            return true
        }
        return false
    }

    private func matchInteger() -> Bool {
        if isAtEnd() { return false }
        if case .integer = peek().type {
            _ = advance()
            return true
        }
        return false
    }

    private func check(_ type: TokenType) -> Bool {
        if isAtEnd() { return false }
        return peek().type == type
    }

    private func advance() -> Token {
        if !isAtEnd() { current += 1 }
        return previous()
    }

    private func isAtEnd() -> Bool {
        return peek().type == .eof
    }

    private func peek() -> Token {
        return tokens[current]
    }

    private func previous() -> Token {
        return tokens[current - 1]
    }
}
