// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct UInt8SMFTests {
}

// MARK: -

extension UInt8SMFTests {
    @Test
    func hex_singleDigitValue() {
        #expect(UInt8(0x00).hex == "00")
        #expect(UInt8(0x01).hex == "01")
        #expect(UInt8(0x0f).hex == "0F")
    }

    @Test
    func hex_twoDigitValue() {
        #expect(UInt8(0x10).hex == "10")
        #expect(UInt8(0x7f).hex == "7F")
        #expect(UInt8(0xff).hex == "FF")
    }

    @Test
    func isMetaEventStatusByte() {
        #expect(UInt8(0xff).isMetaEventStatusByte)
        #expect(!UInt8(0xfe).isMetaEventStatusByte)
        #expect(!UInt8(0x00).isMetaEventStatusByte)
        #expect(!UInt8(0xf0).isMetaEventStatusByte)
    }

    @Test
    func isMIDIEventStatusByte() {
        #expect(UInt8(0x80).isMIDIEventStatusByte)
        #expect(UInt8(0x90).isMIDIEventStatusByte)
        #expect(UInt8(0xa0).isMIDIEventStatusByte)
        #expect(UInt8(0xb0).isMIDIEventStatusByte)
        #expect(UInt8(0xc0).isMIDIEventStatusByte)
        #expect(UInt8(0xd0).isMIDIEventStatusByte)
        #expect(UInt8(0xe0).isMIDIEventStatusByte)
        #expect(!UInt8(0xf0).isMIDIEventStatusByte)
        #expect(!UInt8(0x70).isMIDIEventStatusByte)
        #expect(!UInt8(0xff).isMIDIEventStatusByte)

        #expect(UInt8(0x93).isMIDIEventStatusByte)
        #expect(UInt8(0xbf).isMIDIEventStatusByte)
    }

    @Test
    func isMIDIStatusByte() {
        #expect(!UInt8(0x00).isMIDIStatusByte)
        #expect(!UInt8(0x7f).isMIDIStatusByte)
        #expect(UInt8(0x80).isMIDIStatusByte)
        #expect(UInt8(0x90).isMIDIStatusByte)
        #expect(UInt8(0xff).isMIDIStatusByte)
    }

    @Test
    func isSysExEventStatusByte() {
        #expect(UInt8(0xf0).isSysExEventStatusByte)
        #expect(UInt8(0xf7).isSysExEventStatusByte)
        #expect(!UInt8(0xf1).isSysExEventStatusByte)
        #expect(!UInt8(0xff).isSysExEventStatusByte)
        #expect(!UInt8(0x00).isSysExEventStatusByte)
    }

    @Test
    func isSystemRealTimeByte() {
        #expect(UInt8(0xf8).isSystemRealTimeByte)
        #expect(UInt8(0xfb).isSystemRealTimeByte)
        #expect(UInt8(0xfe).isSystemRealTimeByte)
        #expect(!UInt8(0xf7).isSystemRealTimeByte)
        #expect(!UInt8(0xff).isSystemRealTimeByte)
        #expect(!UInt8(0x00).isSystemRealTimeByte)
    }
}
