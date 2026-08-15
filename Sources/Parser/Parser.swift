class Parser {
    private let tokens: [Token]
    private var current = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parse() -> Program {
        current = 0
        skipNewlines()

        var functions: [FunctionDeclaration] = []
        while match(.fn) {
            functions.append(functionDeclaration())

            if !isAtEnd() && !match(.newline) {
                fatalError(
                    "Parser Error: Expected a new line after function declaration on line \(peek().line)"
                )
            }
            skipNewlines()
        }

        let topLevelExpression = isAtEnd() ? nil : expression()
        skipNewlines()

        if !isAtEnd() {
            fatalError("Parser Error: Unexpected token \(peek().type) on line \(peek().line)")
        }

        return Program(functions: functions, expression: topLevelExpression)
    }

    // MARK: - Parser Grammar Rules

    // functionDeclaration -> identifier "(" parameters? ")" "->" identifier
    private func functionDeclaration() -> FunctionDeclaration {
        let name = consumeIdentifier(message: "Expected a function name after 'fn'")
        consume(.lparen, message: "Expected '(' after function name")

        var parameters: [FunctionParameter] = []
        if !check(.rparen) {
            repeat {
                let parameterName = consumeIdentifier(message: "Expected a parameter name")
                consume(.colon, message: "Expected ':' after parameter name")
                let typeName = consumeIdentifier(message: "Expected a parameter type")
                parameters.append(
                    FunctionParameter(name: parameterName, typeName: typeName)
                )
            } while match(.comma)
        }

        consume(.rparen, message: "Expected ')' after function parameters")
        consume(.arrow, message: "Expected '->' after function parameters")
        let returnType = consumeIdentifier(message: "Expected a return type")

        return FunctionDeclaration(
            name: name,
            parameters: parameters,
            returnType: returnType
        )
    }

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

    // factor -> integer | "(" expression ")"
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
        fatalError("Parser Error: Expected a number or '(' on line \(peek().line)")
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

    private func consume(_ type: TokenType, message: String) {
        if match(type) {
            return
        }
        fatalError("Parser Error: \(message) on line \(peek().line)")
    }

    private func consumeIdentifier(message: String) -> String {
        if case .identifier(let name) = peek().type {
            _ = advance()
            return name
        }
        fatalError("Parser Error: \(message) on line \(peek().line)")
    }

    private func skipNewlines() {
        while match(.newline) {}
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
