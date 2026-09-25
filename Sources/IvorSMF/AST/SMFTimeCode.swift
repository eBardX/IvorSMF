// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorSMPTE

/// The frame rate and number of ticks per frame for SMPTE timecode-based time
/// division.
public struct SMFTimeCode {

    // MARK: Public Initializers

    /// Creates a new `SMFTimeCode` instance with the provided frame rate and
    /// number of ticks per frame, or `nil` if the number of ticks per frame is
    /// out of range.
    ///
    /// - Parameter frameRate:      The SMPTE frame rate.
    /// - Parameter ticksPerFrame:  The number of ticks per frame (0–255).
    public init?(frameRate: SMPTEFrameRate,
                 ticksPerFrame: UInt) {
        guard (0...255).contains(ticksPerFrame)
        else { return nil }

        self.frameRate = frameRate
        self.ticksPerFrame = ticksPerFrame
    }

    // MARK: Public Instance Properties

    /// The SMPTE frame rate.
    public let frameRate: SMPTEFrameRate

    /// The number of ticks per frame.
    public let ticksPerFrame: UInt
}

// MARK: - BytesValueConvertible

extension SMFTimeCode: BytesValueConvertible {

    // MARK: Internal Initializers

    internal init?(bytesValue: [UInt8]) {
        guard bytesValue.count == 2,
              let frameRate = Self._convertToFrameRate(bytesValue[0])
        else { return nil }

        self.init(frameRate: frameRate,
                  ticksPerFrame: UInt(bytesValue[1]))
    }

    // MARK: Internal Instance Properties

    internal var bytesValue: [UInt8]? {
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

// MARK: - Equatable

extension SMFTimeCode: Equatable {
}

// MARK: - Hashable

extension SMFTimeCode: Hashable {
}

// MARK: - Sendable

extension SMFTimeCode: Sendable {
}
