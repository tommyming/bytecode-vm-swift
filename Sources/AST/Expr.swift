// Tommy Han, 2026

/// Abstract Syntax Tree node for arithmetic expressions.
///
/// `number` is a leaf (integer literal); `binary` is an interior node
/// with an operator and two subtrees. Using `indirect` lets the enum
/// reference itself recursively without bloating the value size.
indirect enum Expr {
    case number(Int)
    case binary(op: OptCode, left: Expr, right: Expr)

    // MARK: - Bytecode Generation

    /// Walk the tree in postorder (left, right, operator) and emit
    /// stack-machine bytecode. This is the same ordering the old
    /// single-pass parser produced implicitly.
    func emitBytecode() -> [UInt8] {
        switch self {
        case .number(let value):
            // pushi <value>
            return [OptCode.pushi.rawValue, UInt8(value)]

        case .binary(let op, let left, let right):
            var bytes = left.emitBytecode()
            bytes.append(contentsOf: right.emitBytecode())
            bytes.append(op.rawValue)
            return bytes
        }
    }

    // MARK: - Debug Printing

    /// Print the AST as an indented tree, e.g. for `1 + 2 * 3`:
    ///
    /// ```
    /// AST:
    /// └── BinaryOp(add)
    ///     ├── Number(1)
    ///     └── BinaryOp(multiply)
    ///         ├── Number(2)
    ///         └── Number(3)
    /// ```
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

        case .binary(let op, let left, let right):
            print("\(prefix)\(connector)BinaryOp(\(op))")
            // Left is never last; right always is (binary tree).
            left.printNode(prefix: childPrefix, isLast: false)
            right.printNode(prefix: childPrefix, isLast: true)
        }
    }
}
