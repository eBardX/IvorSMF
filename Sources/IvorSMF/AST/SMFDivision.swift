// © 2025–2026 John Gary Pusey (see LICENSE.md)

/// The time division of an SMF sequence, specifying how event times are
/// measured.
public enum SMFDivision {

    /// Metrical (tick-based) time division, measured in ticks per quarter note.
    case metrical(SMFTickRate)

    /// SMPTE timecode-based time division.
    case timeCode(SMFTimeCode)
}

// MARK: - BytesValueConvertible

extension SMFDivision: BytesValueConvertible {

    // MARK: Internal Initializers

    internal init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 2
        else { return nil }

        if (bytesValue[0] & 0x80) == 0 {
            guard let tickRate = SMFTickRate(bytesValue: bytesValue)
            else { return nil }

            self = .metrical(tickRate)
        } else {
            guard let timeCode = SMFTimeCode(bytesValue: bytesValue)
            else { return nil }

            self = .timeCode(timeCode)
        }
    }

    // MARK: Internal Instance Properties

    internal var bytesValue: [UInt8]? {
        switch self {
        case let .metrical(tickRate):
            tickRate.bytesValue

        case let .timeCode(timeCode):
            timeCode.bytesValue
        }
    }
}

// MARK: - Equatable

extension SMFDivision: Equatable {
}

// MARK: - Hashable

extension SMFDivision: Hashable {
}

// MARK: - Sendable

extension SMFDivision: Sendable {
}
