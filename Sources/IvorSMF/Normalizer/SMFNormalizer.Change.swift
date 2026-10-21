// © 2026 John Gary Pusey (see LICENSE.md)

extension SMFNormalizer {

    // MARK: Public Nested Types

    /// A change applied when normalizing an ``SMFSequence`` to canonical
    /// form.
    public enum Change {

        /// The sequence declared format 0 but had more than one track; it was
        /// reinterpreted as format 1.
        case coercedFormat(from: SMFFormat, to: SMFFormat)

        /// The track had one or more system exclusive continuation packets
        /// with no open multi-packet message to continue; they were converted
        /// to escapes, which is how a reader interprets them.
        case convertedSysExContinuationToEscape(trackIndex: Int)

        /// The track had no terminal End-of-Track meta-event; one was
        /// appended.
        case insertedEndOfTrack(trackIndex: Int)

        /// The track had a device-name meta-event that was not at the start of
        /// the track; it was moved to time zero, ahead of any transmittable
        /// event.
        case relocatedDeviceName(trackIndex: Int)

        /// The track had one or more End-of-Track meta-events that were not
        /// already present as the sole final event; they were consolidated
        /// into a single trailing End-of-Track at the latest tick of any event
        /// in the track.
        case relocatedEndOfTrack(trackIndex: Int)

        /// The track had a sequence-number meta-event that was not at the
        /// start of the track; it was moved to time zero, ahead of any
        /// transmittable event.
        case relocatedSequenceNumber(trackIndex: Int)

        /// The track had a sequence-number meta-event, but the sequence is
        /// format 1 with more than one track; the event was moved to track 0.
        case relocatedSequenceNumberToFirstTrack(trackIndex: Int)

        /// The track had a sequence/track-name meta-event that was not at the
        /// start of the track; it was moved to time zero, ahead of any
        /// transmittable event.
        case relocatedSequenceTrackName(trackIndex: Int)

        /// The track had a SMPTE-offset meta-event that was not at the start of
        /// the track; it was moved to time zero, ahead of any transmittable
        /// event.
        case relocatedSMPTEOffset(trackIndex: Int)

        /// The track had a SMPTE-offset meta-event, but the sequence is format
        /// 1 with more than one track; the event was moved to track 0.
        case relocatedSMPTEOffsetToFirstTrack(trackIndex: Int)

        /// The track had a tempo meta-event, but the sequence is format 1
        /// with more than one track; the event was moved to track 0.
        case relocatedTempo(trackIndex: Int)

        /// The track had a time-signature meta-event, but the sequence is
        /// format 1 with more than one track; the event was moved to
        /// track 0.
        case relocatedTimeSignature(trackIndex: Int)

        /// The track had one or more system exclusive messages that did not
        /// end with 0xF7, either at the end of the track or before another
        /// transmittable event; 0xF7 was appended to the final packet of each.
        case terminatedSysEx(trackIndex: Int)
    }
}

// MARK: -

extension SMFNormalizer.Change {

    // MARK: Public Instance Properties

    /// A human-readable description of this change.
    public var message: String {
        switch self {
        case let .coercedFormat(from, to):
            "Format-\(from.uintValue) sequence had more than one track; reinterpreted as format \(to.uintValue)"

        case let .convertedSysExContinuationToEscape(trackIndex):
            "Track \(trackIndex) had a sysex continuation packet with no message to continue; converted to an escape"

        case let .insertedEndOfTrack(trackIndex):
            "Track \(trackIndex) had no terminal End-of-Track event; one was appended"

        case let .relocatedDeviceName(trackIndex):
            "Track \(trackIndex) had a device-name event that was not at the start of the track; moved there"

        case let .relocatedEndOfTrack(trackIndex):
            "Track \(trackIndex) had a misplaced or duplicate End-of-Track event; consolidated into a single trailing event"

        case let .relocatedSequenceNumber(trackIndex):
            "Track \(trackIndex) had a sequence-number event that was not at the start of the track; moved there"

        case let .relocatedSequenceNumberToFirstTrack(trackIndex):
            "Track \(trackIndex) had a sequence-number event; moved to track 0, which is the only track format 1 allows it in"

        case let .relocatedSequenceTrackName(trackIndex):
            "Track \(trackIndex) had a sequence/track-name event that was not at the start of the track; moved there"

        case let .relocatedSMPTEOffset(trackIndex):
            "Track \(trackIndex) had a SMPTE-offset event that was not at the start of the track; moved there"

        case let .relocatedSMPTEOffsetToFirstTrack(trackIndex):
            "Track \(trackIndex) had a SMPTE-offset event; moved to track 0, which is the only track format 1 allows it in"

        case let .relocatedTempo(trackIndex):
            "Track \(trackIndex) had a tempo event; moved to track 0, which is the only track format 1 allows tempo events in"

        case let .relocatedTimeSignature(trackIndex):
            "Track \(trackIndex) had a time-signature event; moved to track 0, which is the only track format 1 allows time-signature events in"

        case let .terminatedSysEx(trackIndex):
            "Track \(trackIndex) had an unterminated sysex message; 0xF7 was appended"
        }
    }

    /// The zero-based index of the track that this change applies to, or
    /// `nil` for a change that applies to the sequence as a whole.
    public var trackIndex: Int? {
        switch self {
        case .coercedFormat:
            nil

        case let .convertedSysExContinuationToEscape(trackIndex),
             let .insertedEndOfTrack(trackIndex),
             let .relocatedDeviceName(trackIndex),
             let .relocatedEndOfTrack(trackIndex),
             let .relocatedSequenceNumber(trackIndex),
             let .relocatedSequenceNumberToFirstTrack(trackIndex),
             let .relocatedSequenceTrackName(trackIndex),
             let .relocatedSMPTEOffset(trackIndex),
             let .relocatedSMPTEOffsetToFirstTrack(trackIndex),
             let .relocatedTempo(trackIndex),
             let .relocatedTimeSignature(trackIndex),
             let .terminatedSysEx(trackIndex):
            trackIndex
        }
    }
}

// MARK: - Equatable

extension SMFNormalizer.Change: Equatable {
}

// MARK: - Hashable

extension SMFNormalizer.Change: Hashable {
}

// MARK: - Sendable

extension SMFNormalizer.Change: Sendable {
}
