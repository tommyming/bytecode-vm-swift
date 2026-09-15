// Tommy Han, 2026

indirect enum Expr {
    case number(Int)
    case variable(String)
    case call(name: String, arguments: [Expr])
    case unary(op: OptCode, expr: Expr)
    case binary(op: OptCode, left: Expr, right: Expr)

    // MARK: - Debug Printing

    func prettyPrint() {
        print("AST:")
        printNode(prefix: "", isLast: true)
    }

    private func printNode(prefix: String, isLast: Bool) {
        let connector = isLast ? "└── " : "├── "
        let childPrefix = prefix + (isLast ? "    " : "│   ")

        switch self {
        case .number(let value):
            print("\(prefix)\(connector)Number(\(value))")

        case .variable(let name):
            print("\(prefix)\(connector)Variable(\(name))")

        case .call(let name, let arguments):
            print("\(prefix)\(connector)Call(\(name))")
            for (index, argument) in arguments.enumerated() {
                argument.printNode(prefix: childPrefix, isLast: index == arguments.count - 1)
            }

        case .unary(let op, let expr):
            print("\(prefix)\(connector)UnaryOp(\(op))")
            expr.printNode(prefix: childPrefix, isLast: true)

        case .binary(let op, let left, let right):
            print("\(prefix)\(connector)BinaryOp(\(op))")
            left.printNode(prefix: childPrefix, isLast: false)
            right.printNode(prefix: childPrefix, isLast: true)
        }
    }
}

struct Parameter {
    let name: String
    let type: ValueType
}

struct FunctionDecl {
    let name: String
    let parameters: [Parameter]
    let returnType: ValueType? // nil means the function returns nothing
    let body: Expr
}

struct Program {
    let functions: [FunctionDecl]
    let expression: Expr

    func prettyPrint() {
        for function in functions {
            let parameterList = function.parameters
                .map { "\($0.name): \($0.type.name)" }
                .joined(separator: ", ")
            let returnType = function.returnType.map { " -> \($0.name)" } ?? ""
            print("Function \(function.name)(\(parameterList))\(returnType)")
            function.body.prettyPrint()
        }
        print("Main")
        expression.prettyPrint()
    }
}
