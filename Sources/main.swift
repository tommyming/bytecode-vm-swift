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

        if input.allSatisfy(\.isWhitespace) {
            continue
        }

        let lexer = Lexer(source: input)
        let tokens = lexer.scanTokens()

        let parser = Parser(tokens: tokens)
        let program = parser.parse()

        program.prettyPrint()

        let bytecodeProgram = program.emitBytecode()
        vm.load(bytecodeProgram)

        if bytecodeProgram.entryPoint.isEmpty {
            for function in bytecodeProgram.functions {
                print("Loaded function block '\(function.name)'")
            }
        } else {
            vm.run()
        }
    }
}

runREPL()
