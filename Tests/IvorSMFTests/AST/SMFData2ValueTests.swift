// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFData2ValueTests {
}

// MARK: -

extension SMFData2ValueTests {
    @Test
    func bytesValue() {
        #expect(SMFData2Value(uintValue: 0)?.bytesValue == [0x00, 0x00])
        #expect(SMFData2Value(uintValue: 256)?.bytesValue == [0x01, 0x00])
        #expect(SMFData2Value(uintValue: 65_535)?.bytesValue == [0xff, 0xff])
    }

    @Test
    func init_bytesValue() {
        let value = SMFData2Value(bytesValue: [0x01, 0x00])

        #expect(value != nil)
        #expect(value?.uintValue == 256)
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMFData2Value(bytesValue: []) == nil)
        #expect(SMFData2Value(bytesValue: [0x00]) == nil)
        #expect(SMFData2Value(bytesValue: [0x00, 0x00, 0x00]) == nil)
    }

    @Test
    func init_uintValue() {
        #expect(SMFData2Value(uintValue: 0) != nil)
        #expect(SMFData2Value(uintValue: 65_535) != nil)
    }

    @Test
    func init_uintValue_invalid() {
        #expect(SMFData2Value(uintValue: 65_536) == nil)
    }

    @Test
    func isValid() {
        #expect(SMFData2Value.isValid(0))
        #expect(SMFData2Value.isValid(65_535))
        #expect(!SMFData2Value.isValid(65_536))
    }
}
