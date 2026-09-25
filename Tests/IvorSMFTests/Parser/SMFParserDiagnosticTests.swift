// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFParserDiagnosticTests {
}

// MARK: -

extension SMFParserDiagnosticTests {
    @Test
    func hashable() {
        let set: Set<SMFParser.Diagnostic> = [.strayRealTimeByteSkipped,
                                              .strayRealTimeByteSkipped,
                                              .variableLengthQuantityClamped]

        #expect(set.count == 2)
    }

    @Test
    func inequality_differentCase() {
        #expect(SMFParser.Diagnostic.strayRealTimeByteSkipped != .variableLengthQuantityClamped)
    }

    @Test
    func message_chunkLengthClamped() {
        let diagnostic = SMFParser.Diagnostic.chunkLengthClamped(declared: 1_000, available: 42)

        #expect(diagnostic.message.contains("1000"))
        #expect(diagnostic.message.contains("42"))
    }

    @Test
    func message_metaEventLengthClamped() {
        let diagnostic = SMFParser.Diagnostic.metaEventLengthClamped(type: 0x51,
                                                                     declared: 4,
                                                                     expected: 3)

        #expect(diagnostic.message.contains("51"))
        #expect(diagnostic.message.contains("4"))
        #expect(diagnostic.message.contains("3"))
    }

    @Test
    func message_metaEventLengthInvalid() {
        let diagnostic = SMFParser.Diagnostic.metaEventLengthInvalid(type: 0x51,
                                                                     declared: 2,
                                                                     expected: 3)

        #expect(diagnostic.message.contains("51"))
        #expect(diagnostic.message.contains("2"))
        #expect(diagnostic.message.contains("3"))
    }

    @Test
    func message_strayRealTimeByteSkipped() {
        #expect(!SMFParser.Diagnostic.strayRealTimeByteSkipped.message.isEmpty)
    }

    @Test
    func message_trackCountMismatch() {
        let diagnostic = SMFParser.Diagnostic.trackCountMismatch(declared: 5, actual: 3)

        #expect(diagnostic.message.contains("5"))
        #expect(diagnostic.message.contains("3"))
    }

    @Test
    func message_variableLengthQuantityClamped() {
        #expect(!SMFParser.Diagnostic.variableLengthQuantityClamped.message.isEmpty)
    }
}
