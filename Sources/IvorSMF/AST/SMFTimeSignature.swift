// © 2025–2026 John Gary Pusey (see LICENSE.md)

/// A musical time signature as stored in an SMF file.
public struct SMFTimeSignature {

    // MARK: Public Initializers

    /// Creates a new `SMFTimeSignature` instance with the provided values,
    /// or `nil` if any value is out of range.
    ///
    /// - Parameter numerator:      The number of beats per measure.
    ///                             Must be in the range 1–255.
    /// - Parameter denominator:    The beat unit as a power of two
    ///                             (e.g., 2 = quarter note, 3 = eighth
    ///                             note). Must be in the range 0–255.
    /// - Parameter clockRate:      The number of MIDI clocks per metronome
    ///                             click. Must be in the range 1–255.
    /// - Parameter beatRate:       The number of notated 32nd-notes per
    ///                             MIDI quarter note (usually 8). Must be
    ///                             in the range 1–255.
    public init?(numerator: UInt,
                 denominator: UInt,
                 clockRate: UInt,
                 beatRate: UInt) {
        guard (1...255).contains(numerator),
              (0...255).contains(denominator),
              (1...255).contains(clockRate),
              (1...255).contains(beatRate)
        else { return nil }

        self.beatRate = beatRate
        self.clockRate = clockRate
        self.denominator = denominator
        self.numerator = numerator
    }

    // MARK: Public Instance Properties

    /// The number of notated 32nd-notes per MIDI quarter note (usually 8).
    public let beatRate: UInt       // notated 32nd-notes per MIDI quarter note (usually 8)

    /// The number of MIDI clocks per metronome click.
    public let clockRate: UInt      // MIDI clocks per metronome click

    /// The beat unit expressed as a power of two (e.g., 2 = quarter note,
    /// 3 = eighth note).
    public let denominator: UInt    // 1/(2^den) (e.g. 2 == 1/4, 3 == 1/8)

    /// The number of beats per measure.
    public let numerator: UInt
}

// MARK: - BytesValueConvertible

extension SMFTimeSignature: BytesValueConvertible {

    // MARK: Internal Initializers

    internal init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 4
        else { return nil }

        self.init(numerator: UInt(bytesValue[0]),
                  denominator: UInt(bytesValue[1]),
                  clockRate: UInt(bytesValue[2]),
                  beatRate: UInt(bytesValue[3]))
    }

    // MARK: Internal Instance Properties

    internal var bytesValue: [UInt8]? {
        guard let byte0Value = UInt8(exactly: numerator),
              let byte1Value = UInt8(exactly: denominator),
              let byte2Value = UInt8(exactly: clockRate),
              let byte3Value = UInt8(exactly: beatRate)
        else { return nil }

        return [byte0Value, byte1Value, byte2Value, byte3Value]
    }
}

// MARK: - Equatable

extension SMFTimeSignature: Equatable {
}

// MARK: - Hashable

extension SMFTimeSignature: Hashable {
}

// MARK: - Sendable

extension SMFTimeSignature: Sendable {
}
