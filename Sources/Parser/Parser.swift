class Parser {
    private let tokens: [Token]
    private var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens.filter { $0.type != .newline }
    }

    func parse() -> Program {
        current = 0
        var functions: [FunctionDecl] = []
        while match(.funKeyword) {
            functions.append(functionDeclaration())
        }
        let mainExpression = expression()
        if !isAtEnd() {
            fatalError("Parser Error: Unexpected token on line \(peek().line)")
        }
        return Program(functions: functions, expression: mainExpression)
    }

    private func functionDeclaration() -> FunctionDecl {
        let name = consumeIdentifier("Expected a function name")
        consume(.lparen, "Expected '(' after function name")

        var parameters: [String] = []
        if !check(.rparen) {
            repeat {
                parameters.append(consumeIdentifier("Expected a parameter name"))
            } while match(.comma)
        }
        consume(.rparen, "Expected ')' after parameters")
        consume(.leftBrace, "Expected '{' before function body")
        let body = expression()
        consume(.rightBrace, "Expected '}' after function body")
        return FunctionDecl(name: name, parameters: parameters, body: body)
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

    // unary -> ( "-" | "+" ) unary | factor
    // Binds tighter than * / so that "-2 * 3" parses as "(-2) * 3".
    // A leading "+" is a no-op and is discarded.
    private func unary() -> Expr {
        if match(.instruction(.minus)) {
            let expr = unary()
            return .unary(op: .minus, expr: expr)
        }
        if match(.instruction(.add)) {
            return unary()
        }
        return factor()
    }

    // factor -> integer | identifier | call | "(" expression ")"
    private func factor() -> Expr {
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
        if case .identifier(let name) = peek().type {
            _ = advance()
            if !match(.lparen) {
                return .variable(name)
            }

            var arguments: [Expr] = []
            if !check(.rparen) {
                repeat {
                    arguments.append(expression())
                } while match(.comma)
            }
            consume(.rparen, "Expected ')' after arguments")
            return .call(name: name, arguments: arguments)
        }
        fatalError("Parser Error: Expected an expression on line \(peek().line)")
    }

    // MARK: - Helpers

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

    private func consumeIdentifier(_ message: String) -> String {
        if case .identifier(let name) = peek().type {
            _ = advance()
            return name
        }
        fatalError("Parser Error: \(message) on line \(peek().line)")
    }

    private func consume(_ type: TokenType, _ message: String) {
        if !match(type) {
            fatalError("Parser Error: \(message) on line \(peek().line)")
        }
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
