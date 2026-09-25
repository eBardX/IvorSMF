// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFFormatTests {
}

// MARK: -

extension SMFFormatTests {
    @Test
    func bytesValue() {
        #expect(SMFFormat.format0.bytesValue == [0x00, 0x00])
        #expect(SMFFormat.format1.bytesValue == [0x00, 0x01])
        #expect(SMFFormat.format2.bytesValue == [0x00, 0x02])
    }

    @Test
    func format0() {
        #expect(SMFFormat.format0.uintValue == 0)
    }

    @Test
    func format1() {
        #expect(SMFFormat.format1.uintValue == 1)
    }

    @Test
    func format2() {
        #expect(SMFFormat.format2.uintValue == 2)
    }

    @Test
    func init_bytesValue() {
        let format = SMFFormat(bytesValue: [0x00, 0x01])

        #expect(format != nil)
        #expect(format?.uintValue == 1)
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMFFormat(bytesValue: []) == nil)
        #expect(SMFFormat(bytesValue: [0x00]) == nil)
        #expect(SMFFormat(bytesValue: [0x00, 0x00, 0x00]) == nil)
    }

    @Test
    func init_bytesValue_invalidValue() {
        #expect(SMFFormat(bytesValue: [0x00, 0x03]) == nil)
    }

    @Test
    func init_uintValue() {
        #expect(SMFFormat(uintValue: 0) != nil)
        #expect(SMFFormat(uintValue: 1) != nil)
        #expect(SMFFormat(uintValue: 2) != nil)
    }

    @Test
    func init_uintValue_invalid() {
        #expect(SMFFormat(uintValue: 3) == nil)
    }

    @Test
    func isValid() {
        #expect(SMFFormat.isValid(0))
        #expect(SMFFormat.isValid(1))
        #expect(SMFFormat.isValid(2))
        #expect(!SMFFormat.isValid(3))
    }
}
