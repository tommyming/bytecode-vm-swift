// Tommy Han, 2026

/// A tree-walking interpreter that executes the AST directly.
///
/// Unlike the bytecode pipeline (Compiler -> VirtualMachine), this engine never
/// produces or consumes bytecode: each `Expr` node is evaluated recursively,
/// with function arguments held in a per-call environment instead of VM stack
/// slots.
final class Interpreter {
    enum RuntimeError: Error, CustomStringConvertible {
        case unknownVariable(String)
        case unknownFunction(String)
        case wrongArgumentCount(function: String, expected: Int, got: Int)
        case divisionByZero
        case callDepthExceeded(Int)

        var description: String {
            switch self {
            case .unknownVariable(let name):
                return "Unknown variable '\(name)'"
            case .unknownFunction(let name):
                return "Unknown function '\(name)'"
            case .wrongArgumentCount(let function, let expected, let got):
                return "'\(function)' expects \(expected) arguments, got \(got)"
            case .divisionByZero:
                return "Division by 0 error."
            case .callDepthExceeded(let limit):
                return "Call depth exceeded \(limit) nested calls"
            }
        }
    }

    /// Bindings visible inside one active function call. The language has no
    /// assignments or nested scopes yet, so parameters are all a frame holds.
    private typealias Environment = [String: Int]

    private var functions: [String: FunctionDecl] = [:]
    private var callDepth = 0
    private let maxCallDepth: Int

    /// - Parameter maxCallDepth: Safety net against runaway recursion. The VM
    ///   grows its call-frame array on the heap, but this interpreter recurses
    ///   through the native stack, so a limit keeps deep recursion from
    ///   crashing the process instead of reporting an error.
    init(maxCallDepth: Int = 1_000) {
        self.maxCallDepth = maxCallDepth
    }

    /// Runs a program and returns the value of its main expression.
    func run(_ program: Program) throws -> Int {
        for function in program.functions {
            functions[function.name] = function
        }

        callDepth = 0
        return try evaluate(program.expression, in: [:])
    }

    // MARK: - Evaluation

    private func evaluate(_ expression: Expr, in environment: Environment) throws -> Int {
        switch expression {
        case .number(let value):
            return value

        case .variable(let name):
            guard let value = environment[name] else {
                throw RuntimeError.unknownVariable(name)
            }
            return value

        case .call(let name, let arguments):
            return try call(name, arguments: arguments, in: environment)

        case .unary(let op, let expression):
            let value = try evaluate(expression, in: environment)
            // The compiler lowers unary minus to `pushi 0; expr; minus`, i.e. 0 - value.
            return op == .minus ? 0 - value : value

        case .binary(let op, let left, let right):
            let lhs = try evaluate(left, in: environment)
            let rhs = try evaluate(right, in: environment)
            // The type checker only allows arithmetic operators in these nodes.
            if op == .add { return lhs + rhs }
            if op == .minus { return lhs - rhs }
            if op == .multiply { return lhs * rhs }
            guard rhs != 0 else { throw RuntimeError.divisionByZero }
            return lhs / rhs
        }
    }

    /// Mirrors the VM's CALL/RETURN pair: arguments are evaluated in the
    /// caller's environment left to right, bound to the callee's parameters,
    /// and the body's value becomes the call's result.
    private func call(_ name: String, arguments: [Expr], in environment: Environment) throws -> Int {
        guard let function = functions[name] else {
            throw RuntimeError.unknownFunction(name)
        }
        guard arguments.count == function.parameters.count else {
            throw RuntimeError.wrongArgumentCount(
                function: name,
                expected: function.parameters.count,
                got: arguments.count)
        }
        guard callDepth < maxCallDepth else {
            throw RuntimeError.callDepthExceeded(maxCallDepth)
        }

        callDepth += 1
        defer { callDepth -= 1 }

        var frame: Environment = [:]
        frame.reserveCapacity(function.parameters.count)
        for (argument, parameter) in zip(arguments, function.parameters) {
            frame[parameter.name] = try evaluate(argument, in: environment)
        }

        return try evaluate(function.body, in: frame)
    }
}
