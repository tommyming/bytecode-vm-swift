import BytecodeVM
import Foundation

print("Bytecode VM REPL (Type 'exit' to quit)")
print("---------------------------------------")

while true {
    print("> ", terminator: "")

    guard let input = readLine() else { break }
    if input == "exit" { break }
    if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { continue }

    _ = runSource(input, printAST: true)
}
