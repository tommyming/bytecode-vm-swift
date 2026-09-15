import BytecodeVM
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("Error: \(message)\n".utf8))
    exit(1)
}

let arguments = Array(CommandLine.arguments.dropFirst())
let usage = "Usage: bytecode-vm-swift [file.swbyte]"

if arguments == ["--help"] || arguments == ["-h"] {
    print(usage)
    print("Compile and run a .swbyte file, or start the REPL without arguments.")
    exit(0)
}

guard arguments.count <= 1 else {
    fail(usage)
}

if let path = arguments.first {
    let url = URL(fileURLWithPath: path)
    guard url.pathExtension == "swbyte" else {
        fail("Expected a .swbyte file. \(usage)")
    }

    let fileSource: String
    do {
        fileSource = try String(contentsOf: url, encoding: .utf8)
    } catch {
        fail("Could not read '\(path)': \(error.localizedDescription)")
    }
    guard !fileSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        fail("'\(path)' is empty; expected a program with a main expression.")
    }

    guard runSource(fileSource, printAST: true) != nil else {
        exit(1)
    }
    exit(0)
}

print("Bytecode VM REPL (Type 'exit' to quit)")
print("---------------------------------------")

var source = ""
var braceDepth = 0
var parenthesisDepth = 0
var awaitingFunctionBody = false

while true {
    print(source.isEmpty ? "> " : "... ", terminator: "")

    guard let input = readLine() else {
        if !source.isEmpty {
            print("Incomplete input: expected a complete function body and a main expression.")
        }
        break
    }
    if input == "exit" { break }
    let code = input.range(of: "//").map { String(input[..<$0.lowerBound]) } ?? input
    let trimmedInput = code.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmedInput.isEmpty { continue }

    if braceDepth == 0 && trimmedInput.split(whereSeparator: { $0.isWhitespace }).first == "fun" {
        awaitingFunctionBody = true
    }
    source += input + "\n"
    for character in code {
        switch character {
        case "{":
            braceDepth += 1
            awaitingFunctionBody = false
        case "}": braceDepth -= 1
        case "(": parenthesisDepth += 1
        case ")": parenthesisDepth -= 1
        default: break
        }
    }

    if braceDepth > 0 || parenthesisDepth > 0 || awaitingFunctionBody { continue }
    // A program needs a main expression after its function declarations.
    if trimmedInput.last == "}" { continue }

    _ = runSource(source, printAST: true)
    source = ""
    braceDepth = 0
    parenthesisDepth = 0
}
