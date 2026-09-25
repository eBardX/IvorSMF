// © 2026 John Gary Pusey (see LICENSE.md)

extension SMFNormalizer {

    // MARK: Public Nested Types

    /// A change applied when normalizing an ``SMFSequence`` to canonical
    /// form.
    public enum Change {
        /// The sequence declared format 0 but had more than one track; it was
        /// reinterpreted as format 1.
        case coercedFormat(from: SMFFormat, to: SMFFormat)

        /// This track had no terminal End-of-Track meta-event; one was
        /// appended.
        case insertedEndOfTrack(trackIndex: Int)

        /// This track had one or more End-of-Track meta-events that were not
        /// already present as the sole final event; they were consolidated
        /// into a single trailing End-of-Track.
        case relocatedEndOfTrack(trackIndex: Int)

        /// This track had a sequence-number meta-event that did not appear
        /// at time zero; its time was reset to zero.
        case relocatedSequenceNumber(trackIndex: Int)

        /// This track had a tempo meta-event, but the sequence is format 1
        /// with more than one track; the event was moved to track 0.
        case relocatedTempo(trackIndex: Int)

        /// This track had a time-signature meta-event, but the sequence is
        /// format 1 with more than one track; the event was moved to
        /// track 0.
        case relocatedTimeSignature(trackIndex: Int)
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

        case let .insertedEndOfTrack(trackIndex):
            "Track \(trackIndex) had no terminal End-of-Track event; one was appended"

        case let .relocatedEndOfTrack(trackIndex):
            "Track \(trackIndex) had a misplaced or duplicate End-of-Track event; consolidated into a single trailing event"

        case let .relocatedSequenceNumber(trackIndex):
            "Track \(trackIndex) had a sequence-number event that did not appear at time zero; its time was reset to zero"

        case let .relocatedTempo(trackIndex):
            "Track \(trackIndex) had a tempo event; moved to track 0, which is the only track format 1 allows tempo events in"

        case let .relocatedTimeSignature(trackIndex):
            "Track \(trackIndex) had a time-signature event; moved to track 0, which is the only track format 1 allows time-signature events in"
        }
    }

    /// The zero-based index of the track that this change applies to, or
    /// `nil` for a change that applies to the sequence as a whole.
    public var trackIndex: Int? {
        switch self {
        case .coercedFormat:
            nil

        case let .insertedEndOfTrack(trackIndex),
             let .relocatedEndOfTrack(trackIndex),
             let .relocatedSequenceNumber(trackIndex),
             let .relocatedTempo(trackIndex),
             let .relocatedTimeSignature(trackIndex):
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
