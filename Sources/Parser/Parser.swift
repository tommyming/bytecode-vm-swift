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

    // term -> unary ( ( "*" | "/" ) unary )*
    private func term() -> Expr {
        var expr = unary()

        while match(.instruction(.multiply)) || match(.instruction(.divide)) {
            let operatorToken = previous()
            let right = unary()

            expr = .binary(
                op: opCode(from: operatorToken),
                left: expr,
                right: right
            )
        }
        return expr
    }

    // unary -> ( "-" ) unary | factor
    // Binds tighter than * / so that "-2 * 3" parses as "(-2) * 3",
    // and recursive so that "--2" is allowed.
    private func unary() -> Expr {
        if match(.instruction(.minus)) {
            let expr = unary()
            return .unary(op: .minus, expr: expr)
        }
        return factor()
    }

    // factor -> integer | "(" expression ")"
    private func factor() -> Expr {
        // Parenthesized sub-expression: recurse back to the top rule.
        if match(.lparen) {
            let expr = expression()
            if !match(.rparen) {
                fatalError("Parser Error: Expected ')' on line \(peek().line)")
            }
            return expr
        }

        if matchInteger() {
            if case .integer(let value) = previous().type {
                return .number(value)
            }
        }
        fatalError("Parser Error: Expected a number or '(' on line \(peek().line)")
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
