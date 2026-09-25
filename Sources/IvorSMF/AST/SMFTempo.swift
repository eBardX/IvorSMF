// © 2025–2026 John Gary Pusey (see LICENSE.md)

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

// MARK: - BytesValueConvertible

extension SMFTempo: BytesValueConvertible {

    // MARK: Internal Initializers

    internal init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 3
        else { return nil }

        self.init(uintValue: (UInt(bytesValue[0]) << 16) | (UInt(bytesValue[1]) << 8) | UInt(bytesValue[2]))
    }

    // MARK: Internal Instance Properties

    internal var bytesValue: [UInt8]? {
        guard let byte0Value = UInt8(exactly: uintValue >> 16),
              let byte1Value = UInt8(exactly: (uintValue >> 8) & 0xff),
              let byte2Value = UInt8(exactly: uintValue & 0xff)
        else { return nil }

        return [byte0Value, byte1Value, byte2Value]
    }
}
