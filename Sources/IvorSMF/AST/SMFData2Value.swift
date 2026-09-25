// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI
public import XestiTools

/// A 16-bit big-endian SMF data value (0–65,535).
public struct SMFData2Value: UIntRepresentable {

    // MARK: Public Initializers

    /// Creates an `SMFData2Value` instance with the provided value, or
    /// `nil` if the value is not in the valid range.
    ///
    /// - Parameter uintValue:  The data value. Must be in the range
    ///                         0–65,535.
    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    /// The data value.
    public let uintValue: UInt
}

// MARK: -

extension SMFData2Value {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided value is a
    /// valid 16-bit SMF data value.
    ///
    /// - Parameter uintValue:  The value to validate.
    ///
    /// - Returns:  `true` if the value is in the range 0–65,535; otherwise,
    ///             `false`.
    public static func isValid(_ uintValue: UInt) -> Bool {
        (0...65_535).contains(uintValue)
    }
}

// MARK: - MIDIBytesConvertible

extension SMFData2Value: MIDIBytesConvertible {

    // MARK: Public Initializers

    /// Creates an `SMFData2Value` instance from its SMF encoding, or `nil` if
    /// the bytes do not encode a valid data value.
    ///
    /// - Parameter bytesValue: Two bytes holding the value, most significant
    ///                         byte first.
    public init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 2
        else { return nil }

        self.init(uintValue: (UInt(bytesValue[0]) << 8) | UInt(bytesValue[1]))
    }

    // MARK: Public Instance Properties

    /// The SMF encoding of this data value: two bytes holding the value, most
    /// significant byte first. Never `nil`, because every valid data value can
    /// be encoded.
    public var bytesValue: [UInt8]? {
        guard let byte0Value = UInt8(exactly: uintValue >> 8),
              let byte1Value = UInt8(exactly: uintValue & 0xff)
        else { return nil }

        return [byte0Value, byte1Value]
    }
}
