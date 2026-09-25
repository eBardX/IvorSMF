// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// A four-character ASCII type identifier of an SMF chunk.
public struct SMFChunkType: StringRepresentable {

    // MARK: Public Initializers

    /// Creates an `SMFChunkType` instance with the provided string value,
    /// or `nil` if the value is not a valid chunk type identifier.
    ///
    /// - Parameter stringValue:    The chunk type string. Must be exactly
    ///                             four ASCII characters.
    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The chunk type identifier string.
    public let stringValue: String
}

// MARK: -

extension SMFChunkType {

    // MARK: Public Type Properties

    /// The SMF header chunk type (`MThd`).
    public static let header = Self("MThd")

    /// The SMF track chunk type (`MTrk`).
    public static let track = Self("MTrk")

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided value is a
    /// valid SMF chunk type identifier.
    ///
    /// - Parameter stringValue:    The value to validate.
    ///
    /// - Returns:  `true` if the value is exactly four ASCII characters;
    ///             otherwise, `false`.
    public static func isValid(_ stringValue: String) -> Bool {
        stringValue.count == 4 && stringValue.allSatisfy { $0.isASCII }
    }
}
