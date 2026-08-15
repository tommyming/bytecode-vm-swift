// Tommy Han, 2026

struct FunctionParameter: Equatable {
    let name: String
    let typeName: String
}

struct FunctionBlock: Equatable {
    let name: String
    let parameters: [FunctionParameter]
    let returnType: String
    let byteCode: [UInt8]
}

struct BytecodeProgram: Equatable {
    let entryPoint: [UInt8]
    let functions: [FunctionBlock]
}
