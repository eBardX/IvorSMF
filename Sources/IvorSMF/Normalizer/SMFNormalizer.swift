// © 2026 John Gary Pusey (see LICENSE.md)

/// A type that normalizes an SMF sequence to canonical form.
public struct SMFNormalizer {

    // MARK: Public Initializers

    /// Creates a new SMF normalizer.
    public init() {
    }
}

// MARK: -

extension SMFNormalizer {

    // MARK: Public Instance Methods

    /// Returns a copy of the provided sequence normalized to canonical form,
    /// along with an array describing each change applied.
    ///
    /// Normalization is idempotent: calling `normalize(_:)` on an
    /// already-normalized sequence returns it immediately with an empty
    /// changes array.
    ///
    /// Canonical form requires each track to have exactly one End-of-Track
    /// meta-event, as the final event, at a tick greater than or equal to
    /// every other event in the track. Each track is mechanically and
    /// data-preservingly brought into this form: all End-of-Track events are
    /// removed, then a single End-of-Track is appended at the maximum
    /// remaining event tick (or tick zero if the track is otherwise empty).
    /// No musical events are ever dropped.
    ///
    /// Canonical form also requires a format-0 sequence to have exactly one
    /// track. A format-0 sequence with more than one track is reinterpreted
    /// as format 1, which has no such restriction.
    ///
    /// Canonical form also requires that, within a track, a sequence-number
    /// meta-event appear at time zero, and that, in a format-1 sequence with
    /// more than one track, tempo and time-signature meta-events appear only
    /// in the first track. A misplaced sequence-number event has its time
    /// reset to zero; a misplaced tempo or time-signature event is moved to
    /// track 0 at its original tick.
    ///
    /// This clears every ``SMFValidator/Issue`` case that has a mechanical
    /// fix, so a normalized sequence has no validation issues arising from
    /// them. Issues that require a judgment call (such as
    /// ``SMFValidator/Issue/unencodableText(trackIndex:)``) are left to
    /// ``SMFValidator``.
    ///
    /// - Parameter sequence:   The sequence to normalize.
    ///
    /// - Returns:  A tuple of a new ``SMFSequence`` whose
    ///             ``SMFSequence/isNormalized`` is `true`, and an array of
    ///             ``Change`` values describing each normalization applied.
    public func normalize(_ sequence: SMFSequence) -> (SMFSequence, [Change]) {
        guard !sequence.isNormalized
        else { return (sequence, []) }

        var editor = Editor(sequence: sequence)

        return editor.editSequence()
    }
}

// MARK: - Sendable

extension SMFNormalizer: Sendable {
}
