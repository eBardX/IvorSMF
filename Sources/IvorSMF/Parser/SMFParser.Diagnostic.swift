// © 2026 John Gary Pusey (see LICENSE.md)

extension SMFParser {

    // MARK: Public Nested Types

    /// A diagnostic message produced by ``SMFParser`` describing a recovery it
    /// performed while parsing.
    public enum Diagnostic {

        /// A chunk’s declared length exceeded the available data and was clamped
        /// to the remaining bytes.
        case chunkLengthClamped(declared: UInt, available: UInt)

        /// A recognized fixed-length meta-event declared more data bytes than
        /// its type defines; the surplus bytes were ignored (RP-001 p.7).
        case metaEventLengthClamped(type: UInt8, declared: UInt, expected: UInt)

        /// A fixed-length meta-event declared fewer data bytes than its type
        /// defines; the missing bytes cannot be recovered, so the event was
        /// retained as an ``SMFMetaMessage/unknown(_:_:)`` value.
        case metaEventLengthInvalid(type: UInt8, declared: UInt, expected: UInt)

        /// A stray system real-time byte was skipped in the event stream.
        case strayRealTimeByteSkipped

        /// The number of track chunks found differed from the count declared in
        /// the header.
        case trackCountMismatch(declared: UInt, actual: UInt)

        /// A variable-length quantity exceeded the 0x0fffffff maximum defined by
        /// RP-001 (p.2) and was clamped to that maximum.
        case variableLengthQuantityClamped
    }
}

// MARK: -

extension SMFParser.Diagnostic {

    // MARK: Public Instance Properties

    /// A human-readable description of this diagnostic.
    public var message: String {
        switch self {
        case let .chunkLengthClamped(declared, available):
            "Chunk length \(declared) exceeds available data; clamped to \(available)"

        case let .metaEventLengthClamped(type, declared, expected):
            "Meta-event 0x\(String(type, radix: 16)) declared \(declared) data byte(s); "
                + "clamped to expected \(expected)"

        case let .metaEventLengthInvalid(type, declared, expected):
            "Meta-event 0x\(String(type, radix: 16)) declared \(declared) data byte(s); "
                + "expected \(expected) — retained as unrecognized"

        case .strayRealTimeByteSkipped:
            "Stray system real-time byte skipped"

        case let .trackCountMismatch(declared, actual):
            "Header declared \(declared) track(s); found \(actual)"

        case .variableLengthQuantityClamped:
            "Variable-length quantity exceeds 0x0fffffff; clamped to maximum"
        }
    }
}

// MARK: - Equatable

extension SMFParser.Diagnostic: Equatable {
}

// MARK: - Hashable

extension SMFParser.Diagnostic: Hashable {
}

// MARK: - Sendable

extension SMFParser.Diagnostic: Sendable {
}
