// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFChunkTypeTests {
}

// MARK: -

extension SMFChunkTypeTests {
    @Test
    func header() {
        #expect(SMFChunkType.header.stringValue == "MThd")
    }

    @Test
    func init_stringValue() {
        let ct = SMFChunkType(stringValue: "MThd")

        #expect(ct != nil)
        #expect(ct?.stringValue == "MThd")
    }

    @Test
    func init_stringValue_custom() {
        let ct = SMFChunkType(stringValue: "ABCD")

        #expect(ct != nil)
        #expect(ct?.stringValue == "ABCD")
    }

    @Test
    func init_stringValue_invalid_nonASCII() {
        #expect(SMFChunkType(stringValue: "MTh\u{00E9}") == nil)
    }

    @Test
    func init_stringValue_invalid_tooLong() {
        #expect(SMFChunkType(stringValue: "MThdX") == nil)
    }

    @Test
    func init_stringValue_invalid_tooShort() {
        #expect(SMFChunkType(stringValue: "MT") == nil)
    }

    @Test
    func isValid() {
        #expect(SMFChunkType.isValid("MThd"))
        #expect(SMFChunkType.isValid("MTrk"))
        #expect(SMFChunkType.isValid("ABCD"))
        #expect(!SMFChunkType.isValid("AB"))
        #expect(!SMFChunkType.isValid("ABCDE"))
    }

    @Test
    func track() {
        #expect(SMFChunkType.track.stringValue == "MTrk")
    }
}
