// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI

/// The time division of an SMF sequence, specifying how event times are
/// measured.
public enum SMFDivision {

    /// Metrical (tick-based) time division, measured in ticks per quarter note.
    case metrical(SMFTickRate)

    /// SMPTE timecode-based time division.
    case timeCode(SMFTimeCode)
}

// MARK: - Equatable

extension SMFDivision: Equatable {
}

// MARK: - Hashable

extension SMFDivision: Hashable {
}

// MARK: - MIDIBytesConvertible

extension SMFDivision: MIDIBytesConvertible {

    // MARK: Public Initializers

    /// Creates an `SMFDivision` instance from its SMF encoding, or `nil` if the
    /// bytes do not encode a valid time division.
    ///
    /// - Parameter bytesValue: Two bytes, most significant byte first. If the
    ///                         high bit is clear, they hold the number of ticks
    ///                         per quarter note; otherwise, they hold a
    ///                         timecode division.
    public init?(bytesValue: [UInt8]) {
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

    // MARK: Public Instance Properties

    /// The SMF encoding of this time division, as stored in the SMF header
    /// chunk: two bytes, most significant byte first. Never `nil`, because
    /// every valid time division can be encoded.
    public var bytesValue: [UInt8]? {
        switch self {
        case let .metrical(tickRate):
            tickRate.bytesValue

        case let .timeCode(timeCode):
            timeCode.bytesValue
        }
    }
}

// MARK: - Sendable

extension SMFDivision: Sendable {
}
