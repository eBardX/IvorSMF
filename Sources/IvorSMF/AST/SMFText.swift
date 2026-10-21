// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import Foundation
public import IvorMIDI
public import XestiTools

/// A text string stored in an SMF file, whose characters are encodable
/// as single bytes.
///
/// Text is decoded and encoded with the Windows-1252 (“ANSI”) character set,
/// which RP-026 makes the default for Lyric/Display meta-events. Every byte
/// value maps to exactly one character, so any text payload survives a
/// round trip unchanged. A lyric written in another character set, such as
/// Shift-JIS or UTF-16, can be read with ``decodedString(using:)``.
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

    // MARK: Public Instance Methods

    /// Decodes the bytes of this text with the provided string encoding.
    ///
    /// Use this to read a Lyric/Display meta-event written in a character set
    /// other than the default, for example `.shiftJIS` after a `{@JP}` tag,
    /// or `.utf16` when the bytes start with a byte order mark (RP-026 §5).
    ///
    /// - Parameter encoding:   The string encoding of the bytes.
    ///
    /// - Returns:  The decoded string, or `nil` if the bytes are not valid in
    ///             the provided encoding.
    public func decodedString(using encoding: String.Encoding) -> String? {
        guard let bytes = bytesValue
        else { return nil }

        return String(bytes: bytes,
                      encoding: encoding)
    }

    // MARK: Private Type Properties

    // The Windows-1252 characters for bytes 0x80–0x9F, as defined by the WHATWG
    // Encoding Standard. Bytes 0x81, 0x8D, 0x8F, 0x90, and 0x9D are unassigned
    // in Windows-1252 and map to the C1 control characters of the same value,
    // so that every byte decodes to a distinct character.
    private static let cp1252Scalars: [UInt32] = [0x20ac,
                                                  0x0081,
                                                  0x201a,
                                                  0x0192,
                                                  0x201e,
                                                  0x2026,
                                                  0x2020,
                                                  0x2021,
                                                  0x02c6,
                                                  0x2030,
                                                  0x0160,
                                                  0x2039,
                                                  0x0152,
                                                  0x008d,
                                                  0x017d,
                                                  0x008f,
                                                  0x0090,
                                                  0x2018,
                                                  0x2019,
                                                  0x201c,
                                                  0x201d,
                                                  0x2022,
                                                  0x2013,
                                                  0x2014,
                                                  0x02dc,
                                                  0x2122,
                                                  0x0161,
                                                  0x203a,
                                                  0x0153,
                                                  0x009d,
                                                  0x017e,
                                                  0x0178]

    private static let cp1252Bytes: [UInt32: UInt8] =
        Dictionary(uniqueKeysWithValues: cp1252Scalars.enumerated().map { ($1, UInt8(0x80 + $0)) })

    // MARK: Private Type Methods

    private static func _decode(_ byte: UInt8) -> Unicode.Scalar {
        guard (0x80...0x9f).contains(byte),
              let scalar = Unicode.Scalar(cp1252Scalars[Int(byte - 0x80)])
        else { return Unicode.Scalar(byte) }

        return scalar
    }

    private static func _encode(_ scalar: Unicode.Scalar) -> UInt8? {
        if let byte = cp1252Bytes[scalar.value] {
            return byte
        }

        guard let byte = UInt8(exactly: scalar.value),
              !(0x80...0x9f).contains(byte)
        else { return nil }

        return byte
    }
}

// MARK: - MIDIBytesConvertible

extension SMFText: MIDIBytesConvertible {

    // MARK: Public Initializers

    /// Creates an `SMFText` instance from its SMF encoding, or `nil` if the
    /// bytes do not encode a valid text string.
    ///
    /// - Parameter bytesValue: The bytes of the text, one byte per character,
    ///                         in the Windows-1252 character set.
    public init?(bytesValue: [UInt8]) {
        var scalars = String.UnicodeScalarView()

        scalars.append(contentsOf: bytesValue.map(Self._decode))

        self.init(stringValue: String(scalars))
    }

    // MARK: Public Instance Properties

    /// The SMF encoding of this text string: one byte per character in the
    /// Windows-1252 character set, or `nil` if any character is not in that
    /// character set.
    public var bytesValue: [UInt8]? {
        var bytes: [UInt8] = []

        for scalar in stringValue.unicodeScalars {
            guard let byte = Self._encode(scalar)
            else { return nil }

            bytes.append(byte)
        }

        return bytes
    }
}
