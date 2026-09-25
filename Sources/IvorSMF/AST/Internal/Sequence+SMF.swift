// © 2025–2026 John Gary Pusey (see LICENSE.md)

extension Sequence<UInt8> {
    internal var hex: String {
        map { $0.hex }.joined(separator: " ")
    }
}
