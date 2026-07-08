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

        // Pass the raw string to your Lexer
        let lexer = Lexer(source: input)
        let tokens = lexer.scanTokens()

        print("Generated Tokens: \n\(tokens)")

        // Next steps (once implemented):
        // let bytecode = parser.parse(tokens)
        // vm.interpret(bytecode)

        // vm.byteCode = sthElse
        vm.run()
    }
}

// Start the REPL
runREPL()
