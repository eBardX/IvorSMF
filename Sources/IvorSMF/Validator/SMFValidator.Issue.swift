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

        /// The sequence has a number of tracks that is incompatible with its
        /// format.
        case invalidTrackCount(trackCount: Int,
                               format: SMFFormat)

        /// This track has no terminal End-of-Track meta-event.
        case missingEndOfTrack(trackIndex: Int)

        /// A meta-event in this track carries text with one or more characters
        /// that cannot be encoded as single-byte SMF text.
        case unencodableText(trackIndex: Int)
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

        case let .invalidTrackCount(trackCount, format):
            "The sequence has \(trackCount) track(s), which is not valid for format \(format.uintValue)"

        case let .missingEndOfTrack(trackIndex):
            "Track \(trackIndex) is missing a terminal End-of-Track meta-event"

        case let .unencodableText(trackIndex):
            "Track \(trackIndex) has a meta-event whose text contains a character that cannot be encoded as single-byte SMF text"
        }
    }

    /// The zero-based index of the track that contains this issue, or `nil`
    /// for an issue that applies to the sequence as a whole.
    public var trackIndex: Int? {
        switch self {
        case .invalidTrackCount:
            nil

        case let .deltaTimeTooLarge(trackIndex),
             let .eventAfterEndOfTrack(trackIndex),
             let .eventDataTooLarge(trackIndex),
             let .missingEndOfTrack(trackIndex),
             let .unencodableText(trackIndex):
            trackIndex
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
