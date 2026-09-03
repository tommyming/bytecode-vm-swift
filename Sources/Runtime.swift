public func runSource(_ source: String, printAST: Bool = false) -> Int? {
    let tokens = Lexer(source: source).scanTokens()
    let program = Parser(tokens: tokens).parse()
    if printAST {
        program.prettyPrint()
    }
    var compiler = Compiler()
    let vm = VirtualMachine()
    vm.byteCode = compiler.compile(program)
    return vm.run()
}
