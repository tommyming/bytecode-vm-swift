import XCTest
@testable import BytecodeVM

final class FunctionTests: XCTestCase {
    func testCompilesAndRunsFunction() {
        let source = "fun sum(a, b) { a + b } sum(20, 22)"
        let program = Parser(tokens: Lexer(source: source).scanTokens()).parse()
        var compiler = Compiler()
        let vm = VirtualMachine()
        vm.byteCode = compiler.compile(program)

        XCTAssertEqual(vm.run(), 42)
    }

    func testFunctionCanCallAnotherFunction() {
        let source = """
        fun double(value) { value * 2 }
        fun addDouble(a, b) { double(a) + double(b) }
        addDouble(4, 5)
        """
        let program = Parser(tokens: Lexer(source: source).scanTokens()).parse()
        var compiler = Compiler()
        let vm = VirtualMachine()
        vm.byteCode = compiler.compile(program)

        XCTAssertEqual(vm.run(), 18)
    }
}
