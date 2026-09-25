// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension SMFFormatter {

    // MARK: Public Nested Types

    /// An error that occurs when formatting an SMF sequence to binary data.
    public enum Error {

        /// ``SMFFormatter/format(_:)`` was called on a sequence whose
        /// ``SMFSequence/isValidated`` flag is `false`.
        ///
        /// Call ``SMFValidator/validate(_:)`` before ``SMFFormatter/format(_:)``.
        case notValidated
    }
}

// MARK: - EnhancedError

extension SMFFormatter.Error: EnhancedError {

    // MARK: Public Instance Properties

    /// The error category identifying the source module.
    public var category: Category? {
        Category("IvorSMF")
    }

    /// A human-readable description of this error.
    public var message: String {
        switch self {
        case .notValidated:
            "Sequence must be validated before formatting; call SMFValidator.validate(_:) first"
        }
    }
}

// MARK: - Equatable

extension SMFFormatter.Error: Equatable {
}

// MARK: - Sendable

extension SMFFormatter.Error: Sendable {
}
