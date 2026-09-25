// © 2025–2026 John Gary Pusey (see LICENSE.md)

extension Sequence<UInt8> {

    // MARK: Internal Instance Properties

    internal var hex: String {
        map { $0.hex }.joined(separator: " ")
    }
}
