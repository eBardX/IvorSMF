// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorSMPTE
public import XestiTools

/// The absolute time of an SMF event, measured in ticks from the beginning of
/// the track.
public struct SMFEventTime: UIntRepresentable {

    // MARK: Public Initializers

    /// Creates an `SMFEventTime` instance with the provided tick count, or
    /// `nil` if the value is not in the valid range.
    ///
    /// - Parameter uintValue:  The tick count. Must be in the range
    ///                         0–0x7fffffff.
    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    /// The tick count.
    public let uintValue: UInt
}

// MARK: -

extension SMFEventTime {

    // MARK: Public Type Properties

    /// An event time of zero ticks.
    public static let zero = Self(0)

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided value is a valid
    /// SMF event time.
    ///
    /// - Parameter uintValue:  The value to validate.
    ///
    /// - Returns:  `true` if the value is in the range 0–0x7fffffff; otherwise,
    ///             `false`.
    public static func isValid(_ uintValue: UInt) -> Bool {
        (0...0x7fffffff).contains(uintValue)
    }

    // MARK: Public Instance Methods

    /// Returns this event time expressed in beats for the provided tick rate.
    ///
    /// - Parameter tickRate:   The tick rate (ticks per quarter note).
    ///
    /// - Returns:  The time in beats.
    public func beatTime(_ tickRate: SMFTickRate) -> Double {
        Double(uintValue) / Double(tickRate.uintValue)
    }

    /// Returns this event time expressed as a SMPTE timecode value for the
    /// provided timecode-based time division.
    ///
    /// At 29.97 frames per second, the result uses drop-frame numbering.
    /// Timecode wraps around to 00:00:00:00 after 24 hours.
    ///
    /// - Parameter timeCode:   The timecode-based time division.
    ///
    /// - Returns:  The corresponding `SMPTETime` value.
    public func smpteTime(_ timeCode: SMFTimeCode) -> SMPTETime {
        let frameRate = timeCode.frameRate
        let (frames, subframe) = uintValue.quotientAndRemainder(dividingBy: timeCode.ticksPerFrame)
        let fraction = UInt(Double(subframe) * 100 / Double(timeCode.ticksPerFrame))

        return SMPTETime(frameRate: frameRate,
                         frameCount: frames % frameRate.framesPerDay,
                         fraction: fraction).require()
    }
}
