/// Runs the shared front end (lexer -> parser -> type checker) and returns the
/// checked program.
private func parseAndTypeCheck(_ source: String, printAST: Bool) -> Program {
    let tokens = Lexer(source: source).scanTokens()
    let program = Parser(tokens: tokens).parse()
    if printAST {
        program.prettyPrint()
    }
    var typeChecker = TypeChecker()
    typeChecker.check(program)
    return program
}

/// Compiles source text all the way to bytecode without executing it.
public func compileSource(_ source: String, printAST: Bool = false) -> [UInt8] {
    let program = parseAndTypeCheck(source, printAST: printAST)
    var compiler = Compiler()
    return compiler.compile(program)
}

public func runSource(_ source: String, printAST: Bool = false) -> Int? {
    runBytecode(compileSource(source, printAST: printAST))
}

/// Interprets source text directly on the AST, skipping the compiler and the
/// bytecode VM entirely.
public func interpretSource(_ source: String, printAST: Bool = false) -> Int? {
    let program = parseAndTypeCheck(source, printAST: printAST)
    do {
        let result = try Interpreter().run(program)
        print(result)
        return result
    } catch {
        print("Runtime Error: \(error)")
        return nil
    }
}

/// Executes already-compiled bytecode directly, skipping the lexer, parser,
/// type checker, and compiler.
public func runBytecode(_ code: [UInt8]) -> Int? {
    let vm = VirtualMachine()
    vm.byteCode = code
    return vm.run()
}
