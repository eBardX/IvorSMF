// © 2026 John Gary Pusey (see LICENSE.md)

/// A type that validates an SMF sequence against the Standard MIDI Files
/// specification.
public struct SMFValidator {

    // MARK: Public Initializers

    /// Creates a new SMF validator.
    public init() {
    }
}

// MARK: -

extension SMFValidator {

    // MARK: Public Instance Methods

    /// Validates the provided sequence against the Standard MIDI Files
    /// specification and returns any issues found.
    ///
    /// Every remaining ``Issue`` case indicates a violation that will prevent
    /// correct playback or cause ``SMFFormatter`` to throw; deviations that
    /// can be mechanically corrected (a sequence-number event not at time
    /// zero, a tempo or time-signature event outside track 0) are instead
    /// fixed automatically by ``SMFNormalizer``.
    ///
    /// - Parameter sequence:   The sequence to validate.
    ///
    /// - Returns:  A tuple of the validated sequence and an array of
    ///             ``SMFValidator/Issue`` values. The sequence in the tuple is
    ///             a copy of `sequence` with ``SMFSequence/isValidated`` set
    ///             to `true` when no issues are found; otherwise `sequence`
    ///             is returned unchanged (re-validating after fixing issues
    ///             is required). An empty issues array means the sequence is
    ///             fully conformant.
    ///
    /// - Throws:   ``Error/notNormalized`` if ``SMFSequence/isNormalized`` is
    ///             `false`. Call ``SMFNormalizer/normalize(_:)`` before
    ///             calling this method.
    public func validate(_ sequence: SMFSequence) throws(Error) -> (SMFSequence, [Issue]) {
        guard !sequence.isValidated
        else { return (sequence, []) }

        guard sequence.isNormalized
        else { throw Error.notNormalized }

        var checker = Checker(sequence: sequence)

        let issues = checker.checkSequence()

        guard issues.isEmpty
        else { return (sequence, issues) }

        return (SMFSequence(format: sequence.format,
                            division: sequence.division,
                            tracks: sequence.tracks,
                            isNormalized: sequence.isNormalized,
                            isValidated: true), [])
    }
}

// MARK: - Sendable

extension SMFValidator: Sendable {
}
