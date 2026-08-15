// Tommy Han, 2026

struct FunctionDeclaration {
    let name: String
    let parameters: [FunctionParameter]
    let returnType: String

    func emitBytecode() -> FunctionBlock {
        FunctionBlock(
            name: name,
            parameters: parameters,
            returnType: returnType,
            byteCode: []
        )
    }
}

struct Program {
    let functions: [FunctionDeclaration]
    let expression: Expr?

    func emitBytecode() -> BytecodeProgram {
        var entryPoint = expression?.emitBytecode() ?? []
        if expression != nil {
            entryPoint.append(OptCode.halt.rawValue)
        }

        return BytecodeProgram(
            entryPoint: entryPoint,
            functions: functions.map { $0.emitBytecode() }
        )
    }

    func prettyPrint() {
        for function in functions {
            let parameters = function.parameters
                .map { "\($0.name): \($0.typeName)" }
                .joined(separator: ", ")
            print("Function: \(function.name)(\(parameters)) -> \(function.returnType)")
        }

        expression?.prettyPrint()
    }
}
