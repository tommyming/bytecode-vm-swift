/// Compiles source text all the way to bytecode without executing it.
public func compileSource(_ source: String, printAST: Bool = false) -> [UInt8] {
    let tokens = Lexer(source: source).scanTokens()
    let program = Parser(tokens: tokens).parse()
    if printAST {
        program.prettyPrint()
    }
    var typeChecker = TypeChecker()
    typeChecker.check(program)
    var compiler = Compiler()
    return compiler.compile(program)
}

public func runSource(_ source: String, printAST: Bool = false) -> Int? {
    runBytecode(compileSource(source, printAST: printAST))
}

/// Executes already-compiled bytecode directly, skipping the lexer, parser,
/// type checker, and compiler.
public func runBytecode(_ code: [UInt8]) -> Int? {
    let vm = VirtualMachine()
    vm.byteCode = code
    return vm.run()
}
