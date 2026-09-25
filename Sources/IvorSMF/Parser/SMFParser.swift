// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

/// A parser that decodes raw binary data into an ``SMFSequence``.
public struct SMFParser {

    // MARK: Public Initializers

    /// Creates a new `SMFParser` instance.
    public init() {
    }
}

// MARK: -

extension SMFParser {

    // MARK: Public Instance Methods

    /// Parses the provided data and returns the decoded SMF sequence along
    /// with any diagnostic messages produced during recovery.
    ///
    /// The parser always tolerates common real-world deviations from the SMF
    /// specification, recovering where the byte stream allows it and
    /// reporting each recovery as an ``SMFParser/Diagnostic``.
    ///
    /// - Parameter data:   The raw binary data to parse.
    ///
    /// - Returns:  A tuple containing the decoded ``SMFSequence`` and an
    ///             array of ``SMFParser/Diagnostic`` values describing any
    ///             recoveries performed.
    ///
    /// - Throws:   ``SMFParser/Error`` if the data cannot be parsed as a valid
    ///             SMF sequence.
    public func parse(_ data: Data) throws(Error) -> (SMFSequence, [Diagnostic]) {
        var reader = Reader(data: data)

        return try reader.readSequence()
    }
}

// MARK: - Sendable

extension SMFParser: Sendable {
}
