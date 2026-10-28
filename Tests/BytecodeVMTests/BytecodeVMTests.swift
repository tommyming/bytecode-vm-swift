import XCTest
@testable import BytecodeVM

final class BytecodeVMTests: XCTestCase {

    func testInterpreterReturnsMainValue() throws {
        let program = Program(functions: [], expression: .number(5))
        let result = try Interpreter().run(program)
        XCTAssertEqual(result, 5)
    }

    func testLexerHandlesDigitsInNamesAndSkipsUnknownCharacters() {
        let tokens = Lexer(source: "f1 @").scanTokens()
        XCTAssertEqual(tokens.count, 2) // identifier + eof; '@' is reported and skipped
        XCTAssertEqual(tokens.first?.type, .identifier("f1"))
    }

    func testVMStopsRunawayRecursionAtDepthLimit() {
        // main: pushi 0; call -> 7 (1 arg)
        // f:     loadLocal 0; call -> 7 (1 arg); halt
        var bytecode: [UInt8] = []
        bytecode.append(0x01)
        bytecode.append(0) // pushi 0
        bytecode.append(0x09)
        bytecode += [8, 0, 0, 0, 1] // call -> address 8, 1 argument
        bytecode.append(0x08)
        bytecode.append(0) // loadLocal 0
        bytecode.append(0x09)
        bytecode += [8, 0, 0, 0, 1] // call -> address 8, 1 argument
        bytecode.append(0x00) // halt

        let vm = VirtualMachine()
        vm.byteCode = bytecode
        XCTAssertNil(vm.run())
    }
}
