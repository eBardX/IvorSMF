// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension SMFValidator {

    // MARK: Public Nested Types

    /// An error thrown when a sequence operation requires prior
    /// normalization.
    public enum Error {

        /// ``SMFValidator/validate(_:)`` was called on a sequence whose
        /// ``SMFSequence/isNormalized`` flag is `false`.
        ///
        /// Call ``SMFNormalizer/normalize(_:)`` before
        /// ``SMFValidator/validate(_:)``.
        case notNormalized
    }
}

// MARK: - EnhancedError

extension SMFValidator.Error: EnhancedError {

    // MARK: Public Instance Properties

    /// The error category identifying the source module.
    public var category: Category? {
        Category("IvorSMF")
    }

    /// A human-readable description of this error.
    public var message: String {
        switch self {
        case .notNormalized:
            "Sequence must be normalized before validation; call SMFNormalizer.normalize(_:) first"
        }
    }
}

// MARK: - Equatable

extension SMFValidator.Error: Equatable {
}

// MARK: - Sendable

extension SMFValidator.Error: Sendable {
}
