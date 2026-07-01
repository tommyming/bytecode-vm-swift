class VirtualMachine {
    let byteCode: [UInt8]
    private var instPtr = 0
    private var stack: [Int] = []
    private var isRunning = false

    init(byteCode: [UInt8]) {
        self.byteCode = byteCode
    }

    func run() {
        isRunning = true

        while isRunning && instPtr < byteCode.count {
            // 1. FETCH next byte
            let rawOpcode = byteCode[instPtr]
            instPtr += 1

            // Decode the byte into our OpCode enum
            guard let opcode = OptCode(rawValue: rawOpcode) else {
                print("Runtime Error: Unknown instruction 0x\(String(rawOpcode, radix: 16))")
                return
            }

            // 2. DECODE & EXECUTE
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
            }
        }
    }
}
