// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

/// An encoder that converts an ``SMFSequence`` to raw binary data.
public struct SMFFormatter {

    // MARK: Public Initializers

    /// Creates a new `SMFFormatter` instance.
    public init() {
    }
}

// MARK: -

extension SMFFormatter {

    // MARK: Public Instance Methods

    /// Returns the raw binary data encoding of the provided SMF sequence.
    ///
    /// - Parameter sequence:   The SMF sequence to encode.
    ///
    /// - Returns:  The encoded data.
    ///
    /// - Throws:   ``SMFFormatter/Error/notValidated`` if ``SMFSequence/isValidated``
    ///             is `false`. Call ``SMFValidator/validate(_:)`` before
    ///             calling this method.
    public func format(_ sequence: SMFSequence) throws(Error) -> Data {
        guard sequence.isValidated
        else { throw Error.notValidated }

        var writer = Writer(sequence: sequence)

        return writer.writeSequence()
    }
}

// MARK: - Sendable

extension SMFFormatter: Sendable {
}
