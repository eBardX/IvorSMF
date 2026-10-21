// © 2026 John Gary Pusey (see LICENSE.md)

extension SMFValidator {

    // MARK: Public Nested Types

    /// An issue found when validating an ``SMFSequence`` against the Standard
    /// MIDI Files specification.
    public enum Issue {

        /// The delta-time between two consecutive events in this track (or
        /// between time zero and the first event) exceeds the maximum value
        /// encodable as an SMF variable-length quantity.
        case deltaTimeTooLarge(trackIndex: Int)

        /// One or more events follow the End-of-Track meta-event in this track.
        case eventAfterEndOfTrack(trackIndex: Int)

        /// The data of an event in this track exceeds the maximum length
        /// encodable as an SMF variable-length quantity.
        case eventDataTooLarge(trackIndex: Int)

        /// A meta-event in this track has a type byte of 0x80 or greater;
        /// meta-event types are always less than 128 (RP-001 p.7).
        case invalidMetaEventType(trackIndex: Int)

        /// The sequence has a number of tracks that is incompatible with its
        /// format.
        case invalidTrackCount(trackCount: Int,
                               format: SMFFormat)

        /// The track has no terminal End-of-Track meta-event.
        case missingEndOfTrack(trackIndex: Int)

        /// A system exclusive continuation packet in this track has no open
        /// multi-packet message to continue, so a reader would take it for an
        /// escape.
        case orphanSysExContinuation(trackIndex: Int)

        /// A meta-event in this track carries text with one or more characters
        /// that cannot be encoded as single-byte SMF text.
        case unencodableText(trackIndex: Int)

        /// A system exclusive message in this track does not end with 0xF7
        /// before the end of the track or before another transmittable event
        /// (RP-001 p.6).
        case unterminatedSysEx(trackIndex: Int)
    }
}

// MARK: -

extension SMFValidator.Issue {

    // MARK: Public Instance Properties

    /// A human-readable description of this issue.
    public var message: String {
        switch self {
        case let .deltaTimeTooLarge(trackIndex):
            "Track \(trackIndex) has an event whose delta-time from the preceding event is too large to encode"

        case let .eventAfterEndOfTrack(trackIndex):
            "Track \(trackIndex) has events after the End-of-Track meta-event"

        case let .eventDataTooLarge(trackIndex):
            "Track \(trackIndex) has an event whose data is too large to encode"

        case let .invalidMetaEventType(trackIndex):
            "Track \(trackIndex) has a meta-event whose type byte is not less than 128"

        case let .invalidTrackCount(trackCount, format):
            "The sequence has \(trackCount) track(s), which is not valid for format \(format.uintValue)"

        case let .missingEndOfTrack(trackIndex):
            "Track \(trackIndex) is missing a terminal End-of-Track meta-event"

        case let .orphanSysExContinuation(trackIndex):
            "Track \(trackIndex) has a sysex continuation packet with no message to continue"

        case let .unencodableText(trackIndex):
            "Track \(trackIndex) has a meta-event whose text contains a character that cannot be encoded as single-byte SMF text"

        case let .unterminatedSysEx(trackIndex):
            "Track \(trackIndex) has a sysex message that does not end with 0xF7"
        }
    }

    /// The zero-based index of the track that contains this issue, or `nil`
    /// for an issue that applies to the sequence as a whole.
    public var trackIndex: Int? {
        switch self {
        case let .deltaTimeTooLarge(trackIndex),
             let .eventAfterEndOfTrack(trackIndex),
             let .eventDataTooLarge(trackIndex),
             let .invalidMetaEventType(trackIndex),
             let .missingEndOfTrack(trackIndex),
             let .orphanSysExContinuation(trackIndex),
             let .unencodableText(trackIndex),
             let .unterminatedSysEx(trackIndex):
            trackIndex

        case .invalidTrackCount:
            nil
        }
    }
}

// MARK: - Equatable

extension SMFValidator.Issue: Equatable {
}

// MARK: - Hashable

extension SMFValidator.Issue: Hashable {
}

// MARK: - Sendable

extension SMFValidator.Issue: Sendable {
}
