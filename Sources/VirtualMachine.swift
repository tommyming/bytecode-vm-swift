// Tommy Han, 2026

class VirtualMachine {
    var byteCode: [UInt8] = []
    private(set) var functions: [String: FunctionBlock] = [:]
    private var instPtr = 0
    private var stack: [Int] = []
    private var isRunning = false

    func load(_ program: BytecodeProgram) {
        byteCode = program.entryPoint

        for function in program.functions {
            functions[function.name] = function
        }
    }

    func function(named name: String) -> FunctionBlock? {
        functions[name]
    }

    func run() {
        isRunning = true
        instPtr = 0
        stack = []

        while isRunning && instPtr < byteCode.count {
            let rawOpcode = byteCode[instPtr]
            instPtr += 1

            guard let opcode = OptCode(rawValue: rawOpcode) else {
                print("Runtime Error: Unknown instruction 0x\(String(rawOpcode, radix: 16))")
                return
            }

            switch opcode {
            case .halt:
                isRunning = false

            case .pushi:
                // Fetch the immediately following byte as the data payload
                let value = Int(byteCode[instPtr])
                instPtr += 1
                stack.append(value)

            case .add:
                guard stack.count >= 2 else {
                    print("Runtime Error: Stack underflow on ADD")
                    return
                }
                let b = stack.removeLast()
                let a = stack.removeLast()
                stack.append(a + b)
            case .minus:
                guard stack.count >= 2 else {
                    print("Runtime Error: Stack underflow on MINUS")
                    return
                }
                let b = stack.removeLast()
                let a = stack.removeLast()
                stack.append(a - b)
            case .print:
                guard let value = stack.popLast() else {
                    print("Runtime Error: Stack underflow on PRINT")
                    return
                }
                print("VM Output: \(value)")
            case .multiply:
                let b = stack.removeLast()
                let a = stack.removeLast()
                stack.append(a * b)
            case .divide:
                let b = stack.removeLast()
                let a = stack.removeLast()

                guard b != 0 else {
                    runtimeError("Division by 0 error.")
                    return
                }

                stack.append(a / b)

            }
        }

        if let result = stack.first {
            print(result)
        }
    }

    private func runtimeError(_ message: String) {
        print("runtime error: \(message)")
    }
}
