// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFSequencerSpecificTests {
}

// MARK: -

extension SMFSequencerSpecificTests {
    @Test
    func bytesValue() {
        let seqSpec = SMFSequencerSpecific(manufacturerID: [0x00, 0x00, 0x41],
                                           data: [0x01, 0x02])

        #expect(seqSpec?.bytesValue == [0x00, 0x00, 0x41, 0x01, 0x02])
    }

    @Test
    func init_bytesValue_empty() {
        #expect(SMFSequencerSpecific(bytesValue: []) == nil)
    }

    @Test
    func init_bytesValue_oneByteID() {
        let seqSpec = SMFSequencerSpecific(bytesValue: [0x43, 0x7b, 0x00])

        #expect(seqSpec?.manufacturerID == [0x43])
        #expect(seqSpec?.data == [0x7b, 0x00])
    }

    @Test
    func init_bytesValue_threeByteID() {
        let seqSpec = SMFSequencerSpecific(bytesValue: [0x00, 0x20, 0x29])

        #expect(seqSpec?.manufacturerID == [0x00, 0x20, 0x29])
        #expect(seqSpec?.data.isEmpty == true)
    }

    @Test
    func init_bytesValue_truncatedThreeByteID() {
        #expect(SMFSequencerSpecific(bytesValue: [0x00, 0x20]) == nil)
    }

    @Test
    func isValidManufacturerID() {
        #expect(SMFSequencerSpecific.isValidManufacturerID([0x43]))
        #expect(SMFSequencerSpecific.isValidManufacturerID([0x00, 0x20, 0x29]))
        #expect(!SMFSequencerSpecific.isValidManufacturerID([]))
        #expect(!SMFSequencerSpecific.isValidManufacturerID([0x00]))
        #expect(!SMFSequencerSpecific.isValidManufacturerID([0x43, 0x00]))
        #expect(!SMFSequencerSpecific.isValidManufacturerID([0x80]))
        #expect(!SMFSequencerSpecific.isValidManufacturerID([0x00, 0x80, 0x00]))
    }

    @Test
    func roundTrip() {
        let bytes: [UInt8] = [0x00, 0x00, 0x41, 0x10, 0x20]

        #expect(SMFSequencerSpecific(bytesValue: bytes)?.bytesValue == bytes)
    }
}
