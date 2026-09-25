// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI
public import IvorSMPTE

/// The frame rate and number of ticks per frame for SMPTE timecode-based time
/// division.
public struct SMFTimeCode {

    // MARK: Public Initializers

    /// Creates a new `SMFTimeCode` instance with the provided frame rate and
    /// number of ticks per frame, or `nil` if the frame rate cannot be encoded
    /// in a Standard MIDI File or the number of ticks per frame is out of
    /// range.
    ///
    /// - Parameter frameRate:      The SMPTE frame rate. Must be one of the
    ///                             frame rates that SMF supports: `.fps24`,
    ///                             `.fps25`, `.fps2997`, or `.fps30`.
    /// - Parameter ticksPerFrame:  The number of ticks per frame (1–255).
    public init?(frameRate: SMPTEFrameRate,
                 ticksPerFrame: UInt) {
        guard Self.supports(frameRate),
              (1...255).contains(ticksPerFrame)
        else { return nil }

        self.frameRate = frameRate
        self.ticksPerFrame = ticksPerFrame
    }

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the given SMPTE frame rate
    /// can be encoded in a Standard MIDI File.
    ///
    /// SMF supports only four frame rates, both in a timecode division and in
    /// an SMPTE Offset meta-event: `.fps24`, `.fps25`, `.fps2997`, and
    /// `.fps30`.
    ///
    /// - Parameter frameRate:  The SMPTE frame rate.
    ///
    /// - Returns:  `true` if the frame rate can be encoded; otherwise, `false`.
    public static func supports(_ frameRate: SMPTEFrameRate) -> Bool {
        _convertToByteValue(frameRate) != nil
    }

    // MARK: Public Instance Properties

    /// The SMPTE frame rate.
    public let frameRate: SMPTEFrameRate

    /// The number of ticks per frame (1–255).
    public let ticksPerFrame: UInt
}

// MARK: - Equatable

extension SMFTimeCode: Equatable {
}

// MARK: - Hashable

extension SMFTimeCode: Hashable {
}

// MARK: - MIDIBytesConvertible

extension SMFTimeCode: MIDIBytesConvertible {

    // MARK: Public Initializers

    /// Creates an `SMFTimeCode` instance from its SMF encoding, or `nil` if the
    /// bytes do not encode a valid timecode division.
    ///
    /// - Parameter bytesValue: Two bytes: the negated SMPTE frame rate (-24,
    ///                         -25, -29, or -30) in two’s complement, followed
    ///                         by the number of ticks per frame.
    public init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 2,
              let frameRate = Self._convertToFrameRate(bytesValue[0])
        else { return nil }

        self.init(frameRate: frameRate,
                  ticksPerFrame: UInt(bytesValue[1]))
    }

    // MARK: Public Instance Properties

    /// The SMF encoding of this timecode division: two bytes, the negated SMPTE
    /// frame rate (-24, -25, -29, or -30) in two’s complement, followed by the
    /// number of ticks per frame. Never `nil`, because every valid timecode
    /// division can be encoded.
    public var bytesValue: [UInt8]? {
        guard let byte0Value = Self._convertToByteValue(frameRate),
              let byte1Value = UInt8(exactly: ticksPerFrame)
        else { return nil }

        return [byte0Value, byte1Value]
    }

    // MARK: Private Type Methods

    private static func _convertToByteValue(_ frameRate: SMPTEFrameRate) -> UInt8? {
        switch frameRate {
        case .fps24:
            0xe8

        case .fps25:
            0xe7

        case .fps2997:
            0xe3

        case .fps30:
            0xe2

        default:
            nil
        }
    }

    private static func _convertToFrameRate(_ byteValue: UInt8) -> SMPTEFrameRate? {
        switch byteValue {
        case 0xe8:
            .fps24

        case 0xe7:
            .fps25

        case 0xe3:
            .fps2997

        case 0xe2:
            .fps30

        default:
            nil
        }
    }
}

// MARK: - Sendable

extension SMFTimeCode: Sendable {
}
