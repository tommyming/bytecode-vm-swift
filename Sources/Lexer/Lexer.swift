class Lexer {
    private let source: String
    private var tokens: [Token] = []
    private var current: String.Index
    private var line = 1

    // Map your string keywords to your actual OptCode enum
    private let keywords: [String: OptCode] = [
        "halt": .halt,
        "pushi": .pushi,
        "add": .add,
        "minus": .minus,
        "print": .print,
        "multiply": .multiply,
        "divide": .divide,
    ]

    init(source: String) {
        self.source = source
        self.current = source.startIndex
    }

    func scanTokens() -> [Token] {
        while current < source.endIndex {
            skipWhitespace()
            if current >= source.endIndex { break }

            let char = source[current]

            if char == "\n" {
                tokens.append(Token(type: .newline, line: line))
                line += 1
                current = source.index(after: current)
            } else if char.isLetter {
                readIdentifier()
            } else if char.isNumber {
                readNumber()
            } else if char == "+" {  // addition
                tokens.append(Token(type: .instruction(.add), line: line))
                current = source.index(after: current)
            } else if char == "-" {  // subtraction
                tokens.append(Token(type: .instruction(.minus), line: line))
                current = source.index(after: current)
            } else if char == "*" {  // multiplication
                tokens.append(Token(type: .instruction(.multiply), line: line))
                current = source.index(after: current)
            } else if char == "/" {  // division
                tokens.append(Token(type: .instruction(.divide), line: line))
                current = source.index(after: current)
            } else {
                // Ignore or handle invalid characters gracefully
                current = source.index(after: current)
            }
        }

        tokens.append(Token(type: .eof, line: line))
        return tokens
    }

    private func skipWhitespace() {
        while current < source.endIndex {
            let char = source[current]
            // We treat spaces/tabs as whitespace, but keep newlines for line tracking
            if char == " " || char == "\t" || char == "\r" {
                current = source.index(after: current)
            } else {
                break
            }
        }
    }

    private func readIdentifier() {
        let start = current
        while current < source.endIndex && source[current].isLetter {
            current = source.index(after: current)
        }
        let word = String(source[start..<current])

        if let opCode = keywords[word] {
            tokens.append(Token(type: .instruction(opCode), line: line))
        } else {
            print("Lexer Error: Unknown instruction '\(word)' on line \(line)")
        }
    }

    private func readNumber() {
        let start = current

        while current < source.endIndex && source[current].isNumber {
            current = source.index(after: current)
        }
        let numberStr = String(source[start..<current])

        if let value = Int(numberStr) {
            tokens.append(Token(type: .integer(value), line: line))
        } else {
            print("Lexer Error: Invalid integer '\(numberStr)' on line \(line)")
        }
    }
}
