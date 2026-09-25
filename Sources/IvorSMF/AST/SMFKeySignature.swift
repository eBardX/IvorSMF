// © 2025–2026 John Gary Pusey (see LICENSE.md)

/// A musical key signature as stored in an SMF file.
public enum SMFKeySignature {

    /// The key of A-flat major.
    case aFlatMajor

    /// The key of A-flat minor.
    case aFlatMinor

    /// The key of A major.
    case aMajor

    /// The key of A minor.
    case aMinor

    /// The key of A-sharp minor.
    case aSharpMinor

    /// The key of B-flat major.
    case bFlatMajor

    /// The key of B-flat minor.
    case bFlatMinor

    /// The key of B major.
    case bMajor

    /// The key of B minor.
    case bMinor

    /// The key of C-flat major.
    case cFlatMajor

    /// The key of C major.
    case cMajor

    /// The key of C minor.
    case cMinor

    /// The key of C-sharp major.
    case cSharpMajor

    /// The key of C-sharp minor.
    case cSharpMinor

    /// The key of D-flat major.
    case dFlatMajor

    /// The key of D major.
    case dMajor

    /// The key of D minor.
    case dMinor

    /// The key of D-sharp minor.
    case dSharpMinor

    /// The key of E-flat major.
    case eFlatMajor

    /// The key of E-flat minor.
    case eFlatMinor

    /// The key of E major.
    case eMajor

    /// The key of E minor.
    case eMinor

    /// The key of F major.
    case fMajor

    /// The key of F minor.
    case fMinor

    /// The key of F-sharp major.
    case fSharpMajor

    /// The key of F-sharp minor.
    case fSharpMinor

    /// The key of G-flat major.
    case gFlatMajor

    /// The key of G major.
    case gMajor

    /// The key of G minor.
    case gMinor

    /// The key of G-sharp minor.
    case gSharpMinor
}

// MARK: - BytesValueConvertible

extension SMFKeySignature: BytesValueConvertible {

    // MARK: Internal Initializers

    internal init?(bytesValue: [UInt8]) {
        guard let keySignature = Self.keySignaturesByBytesValue[bytesValue]
        else { return nil }

        self = keySignature
    }

    // MARK: Internal Instance Properties

    internal var bytesValue: [UInt8]? {
        Self.bytesValuesByKeySignature[self]
    }

    // MARK: Private Type Properties

    private static let bytesValuesByKeySignature: [SMFKeySignature: [UInt8]] = [.aFlatMajor: [0xfc, 0x00],
                                                                                .aFlatMinor: [0xf9, 0x01],
                                                                                .aMajor: [0x03, 0x00],
                                                                                .aMinor: [0x00, 0x01],
                                                                                .aSharpMinor: [0x07, 0x01],
                                                                                .bFlatMajor: [0xfe, 0x00],
                                                                                .bFlatMinor: [0xfb, 0x01],
                                                                                .bMajor: [0x05, 0x00],
                                                                                .bMinor: [0x02, 0x01],
                                                                                .cFlatMajor: [0xf9, 0x00],
                                                                                .cMajor: [0x00, 0x00],
                                                                                .cMinor: [0xfd, 0x01],
                                                                                .cSharpMajor: [0x07, 0x00],
                                                                                .cSharpMinor: [0x04, 0x01],
                                                                                .dFlatMajor: [0xfb, 0x00],
                                                                                .dMajor: [0x02, 0x00],
                                                                                .dMinor: [0xff, 0x01],
                                                                                .dSharpMinor: [0x06, 0x01],
                                                                                .eFlatMajor: [0xfd, 0x00],
                                                                                .eFlatMinor: [0xfa, 0x01],
                                                                                .eMajor: [0x04, 0x00],
                                                                                .eMinor: [0x01, 0x01],
                                                                                .fMajor: [0xff, 0x00],
                                                                                .fMinor: [0xfc, 0x01],
                                                                                .fSharpMajor: [0x06, 0x00],
                                                                                .fSharpMinor: [0x03, 0x01],
                                                                                .gFlatMajor: [0xfa, 0x00],
                                                                                .gMajor: [0x01, 0x00],
                                                                                .gMinor: [0xfe, 0x01],
                                                                                .gSharpMinor: [0x05, 0x01]]

    private static let keySignaturesByBytesValue: [[UInt8]: SMFKeySignature] =
        Dictionary(uniqueKeysWithValues: bytesValuesByKeySignature.map { ($1, $0) })
}

// MARK: - Equatable

extension SMFKeySignature: Equatable {
}

// MARK: - Hashable

extension SMFKeySignature: Hashable {
}

// MARK: - Sendable

extension SMFKeySignature: Sendable {
}
