// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI
public import XestiTools

/// A MIDI tempo value, in microseconds per quarter note (0–16,777,215).
public struct SMFTempo: UIntRepresentable {

    // MARK: Public Initializers

    /// Creates an `SMFTempo` instance with the provided value, or `nil` if
    /// the value is not in the valid range.
    ///
    /// - Parameter uintValue:  The tempo in microseconds per quarter note.
    ///                         Must be in the range 0–16,777,215.
    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    /// The tempo value in microseconds per quarter note.
    public let uintValue: UInt
}

// MARK: -

extension SMFTempo {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided value is a
    /// valid SMF tempo value.
    ///
    /// - Parameter uintValue:  The value to validate.
    ///
    /// - Returns:  `true` if the value is in the range 0–16,777,215;
    ///             otherwise, `false`.
    public static func isValid(_ uintValue: UInt) -> Bool {
        (0...16_777_215).contains(uintValue)
    }
}

// MARK: - MIDIBytesConvertible

extension SMFTempo: MIDIBytesConvertible {

    // MARK: Public Initializers

    /// Creates an `SMFTempo` instance from its SMF encoding, or `nil` if the
    /// bytes do not encode a valid tempo value.
    ///
    /// - Parameter bytesValue: Three bytes holding the number of microseconds
    ///                         per quarter note, most significant byte first.
    public init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 3
        else { return nil }

        self.init(uintValue: (UInt(bytesValue[0]) << 16) | (UInt(bytesValue[1]) << 8) | UInt(bytesValue[2]))
    }

    // MARK: Public Instance Properties

    /// The SMF encoding of this tempo value: three bytes holding the number of
    /// microseconds per quarter note, most significant byte first. Never
    /// `nil`, because every valid tempo value can be encoded.
    public var bytesValue: [UInt8]? {
        guard let byte0Value = UInt8(exactly: uintValue >> 16),
              let byte1Value = UInt8(exactly: (uintValue >> 8) & 0xff),
              let byte2Value = UInt8(exactly: uintValue & 0xff)
        else { return nil }

        return [byte0Value, byte1Value, byte2Value]
    }
}
