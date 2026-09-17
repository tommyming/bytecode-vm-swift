// Tommy Han, 2026

/// The on-disk `.swbytec` container for compiled bytecode:
///
///     offset  size  field
///     0       4     magic "SWBC"
///     4       1     format version
///     5       4     code length (UInt32, little-endian)
///     9       n     bytecode
public struct BytecodeFile {
    public static let magic: [UInt8] = [0x53, 0x57, 0x42, 0x43] // "SWBC"
    public static let version: UInt8 = 1
    public static let headerSize: Int = magic.count + 5

    public let code: [UInt8]

    public init(code: [UInt8]) {
        self.code = code
    }

    public func serialized() -> [UInt8] {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(Self.headerSize + code.count)
        bytes.append(contentsOf: Self.magic)
        bytes.append(Self.version)
        let length = UInt32(code.count)
        bytes.append(UInt8(truncatingIfNeeded: length))
        bytes.append(UInt8(truncatingIfNeeded: length >> 8))
        bytes.append(UInt8(truncatingIfNeeded: length >> 16))
        bytes.append(UInt8(truncatingIfNeeded: length >> 24))
        bytes.append(contentsOf: code)
        return bytes
    }

    public static func parse(_ bytes: [UInt8]) throws -> BytecodeFile {
        guard bytes.count >= Self.headerSize else {
            throw BytecodeFileError.truncatedHeader
        }
        guard Array(bytes[0..<Self.magic.count]) == Self.magic else {
            throw BytecodeFileError.badMagic
        }
        let version = bytes[4]
        guard version == Self.version else {
            throw BytecodeFileError.unsupportedVersion(version)
        }
        let declaredLength = Int(bytes[5])
            | Int(bytes[6]) << 8
            | Int(bytes[7]) << 16
            | Int(bytes[8]) << 24
        guard declaredLength > 0 else {
            throw BytecodeFileError.emptyCode
        }
        let actualLength = bytes.count - Self.headerSize
        guard declaredLength == actualLength else {
            throw BytecodeFileError.lengthMismatch(expected: declaredLength, actual: actualLength)
        }
        return BytecodeFile(code: Array(bytes[Self.headerSize...]))
    }
}

public enum BytecodeFileError: Error, Equatable, CustomStringConvertible {
    case badMagic
    case unsupportedVersion(UInt8)
    case truncatedHeader
    case emptyCode
    case lengthMismatch(expected: Int, actual: Int)

    public var description: String {
        switch self {
        case .badMagic:
            return "missing 'SWBC' magic header; not a .swbytec file"
        case .unsupportedVersion(let version):
            return "unsupported format version \(version); this runner reads version \(BytecodeFile.version)"
        case .truncatedHeader:
            return "file is too short to contain a .swbytec header"
        case .emptyCode:
            return "file contains no bytecode"
        case .lengthMismatch(let expected, let actual):
            return "header declares \(expected) bytes of code but the file contains \(actual)"
        }
    }
}
