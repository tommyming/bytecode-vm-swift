// Tommy Han, 2026

struct TypeChecker {
    private struct FunctionSignature {
        let parameterTypes: [ValueType]
        let returnType: ValueType?
    }

    private var signatures: [String: FunctionSignature] = [:]
    private var parameterTypes: [String: ValueType] = [:]

    mutating func check(_ program: Program) {
        for function in program.functions {
            signatures[function.name] = FunctionSignature(
                parameterTypes: function.parameters.map(\.type),
                returnType: function.returnType
            )
        }

        for function in program.functions {
            parameterTypes = Dictionary(
                uniqueKeysWithValues: function.parameters.map { ($0.name, $0.type) }
            )
            let bodyType = check(function.body)

            switch (function.returnType, bodyType) {
            case (nil, _):
                // "None" return type: any value the body produces is discarded.
                break
            case (.some(let declared), nil):
                fatalError("Type Error: Function '\(function.name)' declares return type '\(declared.name)' but its body never produces a value")
            case (.some(let declared), .some(let actual)) where declared != actual:
                fatalError("Type Error: Function '\(function.name)' declares return type '\(declared.name)' but its body has type '\(actual.name)'")
            default:
                break
            }
        }

        parameterTypes = [:]
        if check(program.expression) == nil {
            fatalError("Type Error: The main expression must produce a value")
        }
    }

    private mutating func check(_ expression: Expr) -> ValueType? {
        switch expression {
        case .number:
            return .int
        case .string:
            return .string
        case .variable(let name):
            guard let type = parameterTypes[name] else {
                fatalError("Type Error: Unknown variable '\(name)'")
            }
            return type
        case .call(let name, let arguments):
            if name == "string" {
                guard arguments.count == 1 else {
                    fatalError("Type Error: 'string' expects exactly one argument")
                }
                guard check(arguments[0]) != nil else {
                    fatalError("Type Error: Argument of 'string' must produce a value")
                }
                return .string
            }
            guard let signature = signatures[name] else {
                fatalError("Type Error: Unknown function '\(name)'")
            }
            guard signature.parameterTypes.count == arguments.count else {
                fatalError("Type Error: '\(name)' expects \(signature.parameterTypes.count) arguments, got \(arguments.count)")
            }
            for (index, argument) in arguments.enumerated() {
                guard let argumentType = check(argument) else {
                    fatalError("Type Error: Argument \(index + 1) of '\(name)' must produce a value")
                }
                let expected = signature.parameterTypes[index]
                if argumentType != expected {
                    fatalError("Type Error: Argument \(index + 1) of '\(name)' expects type '\(expected.name)', got '\(argumentType.name)'")
                }
            }
            return signature.returnType
        case .unary(_, let expr):
            requireInt(expr, context: "Unary operand")
            return .int
        case .binary(let op, let left, let right):
            if op == .add {
                guard let leftType = check(left), let rightType = check(right) else {
                    fatalError("Type Error: Addition operands must produce a value")
                }
                guard leftType == rightType else {
                    fatalError("Type Error: Addition operands must both be 'int' or both be 'string'")
                }
                return leftType
            }
            requireInt(left, context: "Left operand")
            requireInt(right, context: "Right operand")
            return .int
        }
    }

    private mutating func requireInt(_ expression: Expr, context: String) {
        guard let type = check(expression) else {
            fatalError("Type Error: \(context) must produce a value")
        }
        if type != .int {
            fatalError("Type Error: \(context) must be 'int', got '\(type.name)'")
        }
    }
}
