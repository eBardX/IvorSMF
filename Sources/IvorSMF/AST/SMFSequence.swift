// © 2025–2026 John Gary Pusey (see LICENSE.md)

/// An SMF sequence consisting of a format identifier, a time division,
/// and one or more tracks.
public struct SMFSequence {

    // MARK: Public Initializers

    /// Creates a new `SMFSequence` instance with the provided format,
    /// time division, and tracks.
    ///
    /// The returned sequence has both ``isNormalized`` and ``isValidated``
    /// set to `false`. Call ``SMFNormalizer/normalize(_:)`` and then
    /// ``SMFValidator/validate(_:)`` before ``SMFFormatter/format(_:)``.
    ///
    /// A sequence whose `tracks` count is incompatible with `format` (for
    /// example, a format-0 sequence with more than one track) is accepted
    /// here without error; it is simply not in canonical form. Call
    /// ``SMFNormalizer/normalize(_:)`` to bring it into canonical form
    /// before ``SMFFormatter/format(_:)``.
    ///
    /// - Parameter format:     The SMF format identifier.
    /// - Parameter division:   The time division.
    /// - Parameter tracks:     The tracks in the sequence.
    public init(format: SMFFormat,
                division: SMFDivision,
                tracks: [SMFTrack]) {
        self.init(format: format,
                  division: division,
                  tracks: tracks,
                  isNormalized: false,
                  isValidated: false)
    }

    // MARK: Public Instance Properties

    /// The time division of this sequence.
    public let division: SMFDivision

    /// The SMF format identifier of this sequence.
    public let format: SMFFormat

    /// A Boolean value indicating whether this sequence has been normalized
    /// via ``SMFNormalizer/normalize(_:)``.
    ///
    /// `false` for sequences produced by ``init(format:division:tracks:)``
    /// until ``SMFNormalizer/normalize(_:)`` is called; `true` for all
    /// sequences returned by ``SMFNormalizer/normalize(_:)``.
    public let isNormalized: Bool

    /// A Boolean value indicating whether this sequence has been validated
    /// via ``SMFValidator/validate(_:)``.
    ///
    /// `false` until a successful ``SMFValidator/validate(_:)`` call returns a
    /// copy with this flag set to `true`.
    public let isValidated: Bool

    /// The tracks in this sequence.
    public let tracks: [SMFTrack]

    // MARK: Internal Initializers

    internal init(format: SMFFormat,
                  division: SMFDivision,
                  tracks: [SMFTrack],
                  isNormalized: Bool,
                  isValidated: Bool) {
        self.division = division
        self.format = format
        self.isNormalized = isNormalized
        self.isValidated = isValidated
        self.tracks = tracks
    }
}

// MARK: - Equatable

extension SMFSequence: Equatable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether two sequences are equal.
    ///
    /// Equality compares only ``format``, ``division``, and ``tracks``;
    /// ``isNormalized`` and ``isValidated`` are intentionally excluded
    /// because they are pipeline metadata, not content.
    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        lhs.format == rhs.format
        && lhs.division == rhs.division
        && lhs.tracks == rhs.tracks
    }
}

// MARK: - Hashable

extension SMFSequence: Hashable {

    // MARK: Public Instance Methods

    /// Hashes ``format``, ``division``, and ``tracks``; ``isNormalized`` and
    /// ``isValidated`` are excluded, matching `==`.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(format)
        hasher.combine(division)
        hasher.combine(tracks)
    }
}

// MARK: - Sendable

extension SMFSequence: Sendable {
}
