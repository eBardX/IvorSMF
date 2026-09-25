// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI
public import XestiTools

/// A text string stored in an SMF file, whose characters are encodable
/// as single bytes.
public struct SMFText: StringRepresentable {

    // MARK: Public Initializers

    /// Creates an `SMFText` instance with the provided string value, or
    /// `nil` if the string is not valid for SMF storage.
    ///
    /// - Parameter stringValue:    The text string.
    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The text string.
    public let stringValue: String
}

// MARK: -

extension SMFText {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided string is a
    /// valid SMF text value.
    ///
    /// Every string, including the empty string, is accepted. An empty
    /// text payload is legal in an SMF file (a meta-event may have a length
    /// of zero); in a Lyric/Display meta-event it denotes a melisma
    /// (RP-017 §7). Single-byte encodability is not enforced here — it is
    /// checked when the text is encoded and reported by ``SMFValidator``.
    ///
    /// - Parameter stringValue:    The string value to validate.
    ///
    /// - Returns:  `true` in all cases.
    public static func isValid(_ stringValue: String) -> Bool {
        true
    }
}

// MARK: - MIDIBytesConvertible

extension SMFText: MIDIBytesConvertible {

    // MARK: Public Initializers

    /// Creates an `SMFText` instance from its SMF encoding, or `nil` if the
    /// bytes do not encode a valid text string.
    ///
    /// - Parameter bytesValue: The bytes of the text, one byte per character.
    public init?(bytesValue: [UInt8]) {
        let text = String(bytesValue.map { Character(Unicode.Scalar($0)) })

        self.init(stringValue: text)
    }

    // MARK: Public Instance Properties

    /// The SMF encoding of this text string: one byte per character, or `nil`
    /// if any character cannot be encoded as a single byte.
    public var bytesValue: [UInt8]? {
        var bytes: [UInt8] = []

        for scalar in stringValue.unicodeScalars {
            guard let byte = UInt8(exactly: scalar.value)
            else { return nil }

            bytes.append(byte)
        }

        return bytes
    }
}
