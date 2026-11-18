import XCTest
@testable import BytecodeVM

final class BytecodeVMTests: XCTestCase {

    func testSourceSupportsStringParametersAndConcatenation() {
        let source = """
            fun sum(a: string, b: string) -> string {
                a + b
            }
            sum("tommy", "han")
            """
        XCTAssertEqual(interpretSource(source), .string("tommyhan"))
        XCTAssertEqual(runSource(source), .string("tommyhan"))
    }

    func testSourceSupportsMixedTypeAddition() {
        let declarations = """
            fun prepend(a: int, b: string) -> string {
                a + b
            }
            fun append(a: string, b: int) -> string {
                a + b
            }
            """
        let cases: [(String, ExprValue)] = [
            (#"prepend(42, "x")"#, .string("42x")),
            (#"append("x", -42)"#, .string("x-42")),
            (#"append(prepend(1, "x"), 2) + append("y", 3)"#, .string("1x2y3")),
            (#"-65536 + "世界🙂""#, .string("-65536世界🙂")),
            (#""世界🙂" + 65536"#, .string("世界🙂65536")),
            (#"0 + """#, .string("0")),
            (#""" + 0"#, .string("0")),
            (#"1 + 2 + "x""#, .string("3x")),
            (#""x" + 1 + 2"#, .string("x12")),
            (#""x" + (1 + 2)"#, .string("x3")),
            (#""x" + 2 * 3"#, .string("x6")),
            ("1 + 2", .integer(3))
        ]
        for (expression, expected) in cases {
            let source = declarations + "\n" + expression
            XCTAssertEqual(interpretSource(source), expected, expression)
            XCTAssertEqual(runSource(source), expected, expression)
        }
    }

    func testVMAddsMixedAndMatchingOperandTypes() {
        let cases: [([UInt8], ExprValue)] = [
            ([0x01, 42, 0x05, 1, 0, 0, 0, 0x78, 0x02, 0], .string("42x")),
            ([0x05, 1, 0, 0, 0, 0x78, 0x01, 42, 0x02, 0], .string("x42")),
            ([0x01, 20, 0x01, 22, 0x02, 0], .integer(42)),
            ([0x05, 1, 0, 0, 0, 0x78, 0x05, 1, 0, 0, 0, 0x79, 0x02, 0], .string("xy"))
        ]
        for (code, expected) in cases {
            XCTAssertEqual(runBytecode(code), expected)
        }
    }

    func testSourcePreservesStringContents() {
        let cases: [(String, String)] = [
            ("\"\" + \"\"", ""),
            (#""世界" + "🙂""#, "世界🙂"),
            (#"" // + () {} " + "!""#, " // + () {} !"),
            ("\"first\nsecond\"", "first\nsecond")
        ]
        for (source, expected) in cases {
            XCTAssertEqual(interpretSource(source), .string(expected))
            XCTAssertEqual(runSource(source), .string(expected))
        }
    }

    func testCompilerEmitsUTF8StringWithByteLength() {
        var compiler = Compiler()
        let code = compiler.compile(Program(functions: [], expression: .string("Aé🙂\0")))
        XCTAssertEqual(code, [0x05, 8, 0, 0, 0, 0x41, 0xC3, 0xA9, 0xF0, 0x9F, 0x99, 0x82, 0, 0])
    }

    func testCompiledStringsRoundTripThroughBytecodeFiles() throws {
        for value in ["", "Aé🙂\0", String(repeating: "é", count: 256)] {
            var compiler = Compiler()
            let code = compiler.compile(Program(functions: [], expression: .string(value)))
            let file = try BytecodeFile.parse(BytecodeFile(code: code).serialized())
            XCTAssertEqual(runBytecode(file.code), .string(value))
        }
    }

    func testVMRejectsMalformedStringInstructions() {
        for code: [UInt8] in [
            [0x05],
            [0x05, 0, 0, 0],
            [0x05, 2, 0, 0, 0, 0x41],
            [0x05, 0xFF, 0xFF, 0xFF, 0xFF],
            [0x05, 1, 0, 0, 0, 0xFF, 0]
        ] {
            XCTAssertNil(runBytecode(code))
        }
    }

    func testVMRejectsStringArithmetic() {
        for opcode: UInt8 in [0x03, 0x06, 0x07] {
            XCTAssertNil(runBytecode([0x05, 0, 0, 0, 0, 0x01, 1, opcode, 0]))
        }
    }

    func testInterpreterReturnsMainValue() throws {
        let program = Program(functions: [], expression: .number(5))
        let result = try Interpreter().run(program)
        XCTAssertEqual(result, .integer(5))
    }

    func testInterpreterReturnsStringValue() throws {
        let program = Program(functions: [], expression: .string("hello"))
        XCTAssertEqual(try Interpreter().run(program), .string("hello"))
    }

    func testInterpreterPassesValuesThroughNestedCalls() throws {
        let echo = FunctionDecl(
            name: "echo",
            parameters: [Parameter(name: "value", type: .string)],
            returnType: .string,
            body: .variable("value"))
        let choose = FunctionDecl(
            name: "choose",
            parameters: [
                Parameter(name: "count", type: .int),
                Parameter(name: "text", type: .string)
            ],
            returnType: .string,
            body: .call(name: "echo", arguments: [.variable("text")]))
        let program = Program(
            functions: [echo, choose],
            expression: .call(name: "choose", arguments: [.number(42), .string("hello")]))
        var typeChecker = TypeChecker()
        typeChecker.check(program)

        XCTAssertEqual(try Interpreter().run(program), .string("hello"))
        var compiler = Compiler()
        XCTAssertEqual(runBytecode(compiler.compile(program)), .string("hello"))
    }

    func testInterpretSourcePreservesIntegerArithmeticAndCalls() {
        let source = """
            fun calculate(a: int, b: int) -> int {
                -(a + b) * 3 / 2 - 1
            }
            calculate(4, 2)
            """
        XCTAssertEqual(interpretSource(source), .integer(-10))
        XCTAssertEqual(runSource(source), .integer(-10))
    }

    func testInterpreterReportsDivisionByZero() {
        let program = Program(
            functions: [],
            expression: .binary(op: .divide, left: .number(5), right: .number(0)))
        XCTAssertThrowsError(try Interpreter().run(program)) { error in
            guard case Interpreter.RuntimeError.divisionByZero = error else {
                return XCTFail("Expected division by zero, got \(error)")
            }
        }
    }

    func testExpressionValuesPrintTheirContents() {
        XCTAssertEqual(String(describing: ExprValue.integer(42)), "42")
        XCTAssertEqual(String(describing: ExprValue.string("hello")), "hello")
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
