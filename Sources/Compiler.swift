struct Compiler {
    private struct CallSite {
        let addressIndex: Int
        let functionName: String
        let argumentCount: Int
    }

    private var bytecode: [UInt8] = []
    private var functionAddresses: [String: Int] = [:]
    private var parameterCounts: [String: Int] = [:]
    private var callSites: [CallSite] = []

    mutating func compile(_ program: Program) -> [UInt8] {
        for function in program.functions {
            parameterCounts[function.name] = function.parameters.count
        }

        emit(program.expression, parameters: [:])
        bytecode.append(OptCode.halt.rawValue)

        for function in program.functions {
            functionAddresses[function.name] = bytecode.count
            let parameters = Dictionary(uniqueKeysWithValues: function.parameters.enumerated().map { ($0.element.name, $0.offset) })
            emit(function.body, parameters: parameters)
            bytecode.append(OptCode.returnValue.rawValue)
        }

        for callSite in callSites {
            guard let address = functionAddresses[callSite.functionName],
                  let expectedArguments = parameterCounts[callSite.functionName] else {
                fatalError("Compiler Error: Unknown function '\(callSite.functionName)'")
            }
            guard expectedArguments == callSite.argumentCount else {
                fatalError("Compiler Error: '\(callSite.functionName)' expects \(expectedArguments) arguments, got \(callSite.argumentCount)")
            }
            bytecode[callSite.addressIndex] = UInt8(truncatingIfNeeded: address)
            bytecode[callSite.addressIndex + 1] = UInt8(truncatingIfNeeded: address >> 8)
            bytecode[callSite.addressIndex + 2] = UInt8(truncatingIfNeeded: address >> 16)
            bytecode[callSite.addressIndex + 3] = UInt8(truncatingIfNeeded: address >> 24)
        }

        return bytecode
    }

    private mutating func emit(_ expression: Expr, parameters: [String: Int]) {
        switch expression {
        case .number(let value):
            bytecode.append(contentsOf: [OptCode.pushi.rawValue, UInt8(value)])
        case .variable(let name):
            guard let index = parameters[name] else {
                fatalError("Compiler Error: Unknown variable '\(name)'")
            }
            bytecode.append(contentsOf: [OptCode.loadLocal.rawValue, UInt8(index)])
        case .call(let name, let arguments):
            for argument in arguments {
                emit(argument, parameters: parameters)
            }
            bytecode.append(OptCode.call.rawValue)
            let addressIndex = bytecode.count
            bytecode.append(contentsOf: [0, 0, 0, 0])
            bytecode.append(UInt8(arguments.count))
            callSites.append(CallSite(addressIndex: addressIndex, functionName: name, argumentCount: arguments.count))
        case .unary(let op, let expression):
            bytecode.append(contentsOf: [OptCode.pushi.rawValue, 0])
            emit(expression, parameters: parameters)
            bytecode.append(op.rawValue)
        case .binary(let op, let left, let right):
            emit(left, parameters: parameters)
            emit(right, parameters: parameters)
            bytecode.append(op.rawValue)
        }
    }
}
