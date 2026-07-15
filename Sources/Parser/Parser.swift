class Parser {
    private let tokens: [Token]
    private var current = 0
    private var bytecode: [UInt8] = []

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func parse() -> [UInt8] {
        bytecode.removeAll()

        // Parse the expression and write instructions to the bytecode array
        expression()

        // Always end with a halt instruction
        bytecode.append(OptCode.halt.rawValue)
        return bytecode
    }

    // MARK: - Parser Grammar Rules

    // expression -> term ( ( "+" | "-" ) term )*
    private func expression() {
        term()

        while match(.instruction(.add)) || match(.instruction(.minus)) {
            let operatorToken = previous()

            // Parse the right-hand side of the operator
            term()

            // Emit the math instruction AFTER both operands are pushed onto the stack
            if operatorToken.type == .instruction(.add) {
                bytecode.append(OptCode.add.rawValue)
            } else if operatorToken.type == .instruction(.minus) {
                bytecode.append(OptCode.minus.rawValue)
            }
        }
    }

    // term -> factor ( ( "*" | "/" ) factor )*
    private func term() {
        factor()

        while match(.instruction(.multiply)) || match(.instruction(.divide)) {
            let operatorToken = previous()

            factor()

            if operatorToken.type == .instruction(.multiply) {
                bytecode.append(OptCode.multiply.rawValue)
            } else if operatorToken.type == .instruction(.divide) {
                bytecode.append(OptCode.divide.rawValue)
            }
        }
    }

    // factor -> integer
    private func factor() {
        if matchInteger() {
            if case let .integer(value) = previous().type {
                // Emit the push instruction and then the literal value
                bytecode.append(OptCode.pushi.rawValue)
                bytecode.append(UInt8(value)) // Assuming small integers for simplicity
            }
            return
        }

        fatalError("Parser Error: Expected a number on line \(peek().line)")
    }

    // MARK: - Token Traversal Helpers

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
