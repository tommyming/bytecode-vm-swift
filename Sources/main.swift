// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Required OptCode
enum OptCode: UInt8 {
    case halt = 0x00
    case pushi = 0x01
    case add = 0x02
    case minus = 0x03
    case print = 0x04
}

let program: [UInt8] = [
    OptCode.pushi.rawValue, 24,
    OptCode.pushi.rawValue, 8,
    OptCode.minus.rawValue,
    OptCode.pushi.rawValue, 16,
    OptCode.add.rawValue,
    OptCode.print.rawValue,
    OptCode.halt.rawValue,
]

// Initialize and execute
let vm = VirtualMachine(byteCode: program)
vm.run()
