// Tommy Han, 2026

class VirtualMachine {
    private struct CallFrame {
        let returnAddress: Int
        let stackBase: Int
    }

    var byteCode: [UInt8] = []
    private var instPtr = 0
    private var stack: [Int] = []
    private var callFrames: [CallFrame] = []
    private var isRunning = false

    @discardableResult
    func run() -> Int? {
        isRunning = true
        instPtr = 0
        stack = []
        callFrames = []

        while isRunning && instPtr < byteCode.count {
            let rawOpcode = byteCode[instPtr]
            instPtr += 1

            guard let opcode = OptCode(rawValue: rawOpcode) else {
                print("Runtime Error: Unknown instruction 0x\(String(rawOpcode, radix: 16))")
                return nil
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
                    return nil
                }
                let b = stack.removeLast()
                let a = stack.removeLast()
                stack.append(a + b)
            case .minus:
                guard stack.count >= 2 else {
                    print("Runtime Error: Stack underflow on MINUS")
                    return nil
                }
                let b = stack.removeLast()
                let a = stack.removeLast()
                stack.append(a - b)
            case .print:
                guard let value = stack.popLast() else {
                    print("Runtime Error: Stack underflow on PRINT")
                    return nil
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
                    return nil
                }

                stack.append(a / b)

            case .loadLocal:
                let index = Int(byteCode[instPtr])
                instPtr += 1
                let stackBase = callFrames.last?.stackBase ?? 0
                stack.append(stack[stackBase + index])

            case .call:
                let address = Int(byteCode[instPtr])
                    | Int(byteCode[instPtr + 1]) << 8
                    | Int(byteCode[instPtr + 2]) << 16
                    | Int(byteCode[instPtr + 3]) << 24
                let argumentCount = Int(byteCode[instPtr + 4])
                instPtr += 5
                callFrames.append(CallFrame(returnAddress: instPtr, stackBase: stack.count - argumentCount))
                instPtr = address

            case .returnValue:
                let result = stack.removeLast()
                let frame = callFrames.removeLast()
                stack.removeSubrange(frame.stackBase..<stack.count)
                stack.append(result)
                instPtr = frame.returnAddress

            }
        }

        if let result = stack.last {
            print("\(result)")
        }
        return stack.last
    }

    private func runtimeError(_ message: String) {
        print("runtime error: \(message)")
    }
}
