// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// An SMF file format identifier (0–2).
public struct SMFFormat: UIntRepresentable {

    // MARK: Public Initializers

    /// Creates an `SMFFormat` instance with the provided format identifier,
    /// or `nil` if the value is not a valid format identifier.
    ///
    /// - Parameter uintValue:  The format identifier. Must be in the range
    ///                         0–2.
    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    /// The format identifier.
    public let uintValue: UInt
}

// MARK: -

extension SMFFormat {

    // MARK: Public Type Properties

    /// Format 0: a single-track sequence.
    public static let format0 = Self(0)

    /// Format 1: a multi-track sequence with synchronized tracks.
    public static let format1 = Self(1)

    /// Format 2: a multi-track sequence with asynchronous tracks.
    public static let format2 = Self(2)

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided value is a
    /// valid SMF format identifier.
    ///
    /// - Parameter uintValue:  The value to validate.
    ///
    /// - Returns:  `true` if the value is in the range 0–2; otherwise,
    ///             `false`.
    public static func isValid(_ uintValue: UInt) -> Bool {
        (0...2).contains(uintValue)
    }
}

// MARK: - BytesValueConvertible

extension SMFFormat: BytesValueConvertible {

    // MARK: Internal Initializers

    internal init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 2
        else { return nil }

        self.init(uintValue: (UInt(bytesValue[0]) << 8) | UInt(bytesValue[1]))
    }

    // MARK: Internal Instance Properties

    internal var bytesValue: [UInt8]? {
        guard let byte0Value = UInt8(exactly: uintValue >> 8),
              let byte1Value = UInt8(exactly: uintValue & 0xff)
        else { return nil }

        return [byte0Value, byte1Value]
    }
}
