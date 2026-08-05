// Tommy Han, 2026

indirect enum Expr {
    case number(Int)
    case unary(op: OptCode, expr: Expr)
    case binary(op: OptCode, left: Expr, right: Expr)

    // MARK: - Bytecode Generation

    func emitBytecode() -> [UInt8] {
        switch self {
        case .number(let value):
            return [OptCode.pushi.rawValue, UInt8(value)]

        case .unary(let op, let expr):
            // Desugar unary minus as (0 - expr) so no new VM opcode is needed.
            var bytes: [UInt8] = [OptCode.pushi.rawValue, 0]
            bytes.append(contentsOf: expr.emitBytecode())
            bytes.append(op.rawValue)
            return bytes

        case .binary(let op, let left, let right):
            var bytes = left.emitBytecode()
            bytes.append(contentsOf: right.emitBytecode())
            bytes.append(op.rawValue)
            return bytes
        }
    }

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
