import BytecodeVM
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("Error: \(message)\n".utf8))
    exit(1)
}

let usage = """
Usage: bytecode-vm-swift [options] [file]

  (no arguments)                Start the REPL.
  file.swbyte                   Compile and run a source file on the bytecode VM.
  file.swbyte -o out.swbytec    Compile source to a bytecode file without running it.
  file.swbytec                  Run a compiled bytecode file directly.

Options:
  -i, --interpret               Run .swbyte files (and the REPL) on the
                                tree-walking interpreter instead of the
                                bytecode VM.
  -o output.swbytec             Write compiled bytecode to a file.
  -h, --help                    Show this message.
"""

func runREPL(useInterpreter: Bool) {
    let engine = useInterpreter ? "tree-walking interpreter" : "bytecode VM"
    print("Bytecode VM REPL — \(engine) (Type 'exit' to quit)")
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

        if useInterpreter {
            _ = interpretSource(source, printAST: true)
        } else {
            _ = runSource(source, printAST: true)
        }
        source = ""
        braceDepth = 0
        parenthesisDepth = 0
    }
}

func runCompiledFile(at path: String) {
    let url = URL(fileURLWithPath: path)
    let fileData: Data
    do {
        fileData = try Data(contentsOf: url)
    } catch {
        fail("Could not read '\(path)': \(error.localizedDescription)")
    }

    let file: BytecodeFile
    do {
        file = try BytecodeFile.parse([UInt8](fileData))
    } catch let error as BytecodeFileError {
        fail("'\(path)': \(error.description)")
    } catch {
        fail("'\(path)': \(error)")
    }

    guard runBytecode(file.code) != nil else {
        exit(1)
    }
    exit(0)
}

func compileToFile(sourcePath: String, outputPath: String) {
    let url = URL(fileURLWithPath: sourcePath)
    let fileSource: String
    do {
        fileSource = try String(contentsOf: url, encoding: .utf8)
    } catch {
        fail("Could not read '\(sourcePath)': \(error.localizedDescription)")
    }
    guard !fileSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        fail("'\(sourcePath)' is empty; expected a program with a main expression.")
    }

    let bytecode = compileSource(fileSource)
    do {
        try Data(BytecodeFile(code: bytecode).serialized())
            .write(to: URL(fileURLWithPath: outputPath), options: .atomic)
    } catch {
        fail("Could not write '\(outputPath)': \(error.localizedDescription)")
    }
    print("Wrote \(outputPath) (\(bytecode.count) bytes of bytecode)")
    exit(0)
}

func runSourceFile(at path: String, useInterpreter: Bool) {
    let url = URL(fileURLWithPath: path)
    let fileSource: String
    do {
        fileSource = try String(contentsOf: url, encoding: .utf8)
    } catch {
        fail("Could not read '\(path)': \(error.localizedDescription)")
    }
    guard !fileSource.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        fail("'\(path)' is empty; expected a program with a main expression.")
    }

    let result = useInterpreter
        ? interpretSource(fileSource, printAST: true)
        : runSource(fileSource, printAST: true)
    guard result != nil else {
        exit(1)
    }
    exit(0)
}

let arguments = Array(CommandLine.arguments.dropFirst())

if arguments == ["--help"] || arguments == ["-h"] {
    print(usage)
    exit(0)
}

var sourcePath: String?
var outputPath: String?
var useInterpreter = false
var index = 0
while index < arguments.count {
    let argument = arguments[index]
    if argument == "-i" || argument == "--interpret" {
        useInterpreter = true
    } else if argument == "-o" {
        index += 1
        guard index < arguments.count else {
            fail("Missing path after '-o'.\n\(usage)")
        }
        outputPath = arguments[index]
    } else {
        guard sourcePath == nil else {
            fail("Unexpected argument '\(argument)'.\n\(usage)")
        }
        sourcePath = argument
    }
    index += 1
}

guard let sourcePath else {
    runREPL(useInterpreter: useInterpreter)
    exit(0)
}

let sourceExtension = URL(fileURLWithPath: sourcePath).pathExtension.lowercased()
switch sourceExtension {
case "swbytec":
    if useInterpreter {
        fail("'-i/--interpret' only applies to .swbyte source files; .swbytec files must run on the VM.\n\(usage)")
    }
    if outputPath != nil {
        fail("'-o' only applies when compiling a .swbyte source file.\n\(usage)")
    }
    runCompiledFile(at: sourcePath)
case "swbyte":
    if let outputPath {
        guard URL(fileURLWithPath: outputPath).pathExtension.lowercased() == "swbytec" else {
            fail("Output file should use the .swbytec extension.")
        }
        if useInterpreter {
            fail("Cannot combine '-i/--interpret' with '-o'; interpreting produces no bytecode.\n\(usage)")
        }
        compileToFile(sourcePath: sourcePath, outputPath: outputPath)
    }
    runSourceFile(at: sourcePath, useInterpreter: useInterpreter)
default:
    fail("Expected a .swbyte or .swbytec file. \(usage)")
}
