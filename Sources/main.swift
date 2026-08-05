import Foundation

let vm = VirtualMachine()

@MainActor func runREPL() {
    print("Bytecode VM REPL (Type 'exit' to quit)")
    print("---------------------------------------")

    while true {
        print("> ", terminator: "")

        guard let input = readLine() else { break }

        if input == "exit" {
            break
        }

        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            continue
        }

        let lexer = Lexer(source: input)
        let tokens = lexer.scanTokens()

        let parser = Parser(tokens: tokens)
        let ast = parser.parse()

        ast.prettyPrint()

        var byteCode = ast.emitBytecode()
        byteCode.append(OptCode.halt.rawValue)
        vm.byteCode = byteCode

        vm.run()
    }
}

runREPL()
