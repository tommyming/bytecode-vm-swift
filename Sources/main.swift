// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

let vm = VirtualMachine()

@MainActor func runREPL() {
    print("Bytecode VM REPL (Type 'exit' to quit)")
    print("---------------------------------------")

    while true {
        print("> ", terminator: "")  // Prints the prompt without a newline

        // Wait for user input
        guard let input = readLine() else { break }

        // Provide a way to exit the loop
        if input == "exit" {
            break
        }

        // Skip empty inputs
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            continue
        }

        // Lex raw text into tokens
        let lexer = Lexer(source: input)
        let tokens = lexer.scanTokens()

        // Parse tokens into an AST, then emit bytecode from the tree
        let parser = Parser(tokens: tokens)
        let ast = parser.parse()

        // Debug: visualize the parsed AST before running
        ast.prettyPrint()

        // Generate bytecode and append the halt terminator
        var byteCode = ast.emitBytecode()
        byteCode.append(OptCode.halt.rawValue)
        vm.byteCode = byteCode

        vm.run()
    }
}

// Start the REPL
runREPL()
