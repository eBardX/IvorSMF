// © 2025–2026 John Gary Pusey (see LICENSE.md)

// A type that can be converted to and from an array of bytes.
internal protocol BytesValueConvertible {

    init?(bytesValue: [UInt8])

    var bytesValue: [UInt8]? { get }
}
