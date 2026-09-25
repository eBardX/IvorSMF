// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFKeySignatureTests {
}

// MARK: -

extension SMFKeySignatureTests {
    @Test
    func init_bytesValue_invalid() {
        #expect(SMFKeySignature(bytesValue: []) == nil)
        #expect(SMFKeySignature(bytesValue: [0x00]) == nil)
        #expect(SMFKeySignature(bytesValue: [0x00, 0x02]) == nil)
        #expect(SMFKeySignature(bytesValue: [0x08, 0x00]) == nil)
    }

    @Test
    func roundTrip_flatKeys() {
        let cases: [(SMFKeySignature, [UInt8])] = [(.fMajor, [0xff, 0x00]),
                                                   (.dMinor, [0xff, 0x01]),
                                                   (.bFlatMajor, [0xfe, 0x00]),
                                                   (.gMinor, [0xfe, 0x01]),
                                                   (.eFlatMajor, [0xfd, 0x00]),
                                                   (.cMinor, [0xfd, 0x01]),
                                                   (.aFlatMajor, [0xfc, 0x00]),
                                                   (.fMinor, [0xfc, 0x01]),
                                                   (.dFlatMajor, [0xfb, 0x00]),
                                                   (.bFlatMinor, [0xfb, 0x01]),
                                                   (.gFlatMajor, [0xfa, 0x00]),
                                                   (.eFlatMinor, [0xfa, 0x01]),
                                                   (.cFlatMajor, [0xf9, 0x00]),
                                                   (.aFlatMinor, [0xf9, 0x01])]

        for (keySig, bytes) in cases {
            #expect(keySig.bytesValue == bytes)
            #expect(SMFKeySignature(bytesValue: bytes) == keySig)
        }
    }

    @Test
    func roundTrip_naturalKey() {
        #expect(SMFKeySignature.cMajor.bytesValue == [0x00, 0x00])
        #expect(SMFKeySignature(bytesValue: [0x00, 0x00]) == .cMajor)
        #expect(SMFKeySignature.aMinor.bytesValue == [0x00, 0x01])
        #expect(SMFKeySignature(bytesValue: [0x00, 0x01]) == .aMinor)
    }

    @Test
    func roundTrip_sharpKeys() {
        let cases: [(SMFKeySignature, [UInt8])] = [(.gMajor, [0x01, 0x00]),
                                                   (.eMinor, [0x01, 0x01]),
                                                   (.dMajor, [0x02, 0x00]),
                                                   (.bMinor, [0x02, 0x01]),
                                                   (.aMajor, [0x03, 0x00]),
                                                   (.fSharpMinor, [0x03, 0x01]),
                                                   (.eMajor, [0x04, 0x00]),
                                                   (.cSharpMinor, [0x04, 0x01]),
                                                   (.bMajor, [0x05, 0x00]),
                                                   (.gSharpMinor, [0x05, 0x01]),
                                                   (.fSharpMajor, [0x06, 0x00]),
                                                   (.dSharpMinor, [0x06, 0x01]),
                                                   (.cSharpMajor, [0x07, 0x00]),
                                                   (.aSharpMinor, [0x07, 0x01])]

        for (keySig, bytes) in cases {
            #expect(keySig.bytesValue == bytes)
            #expect(SMFKeySignature(bytesValue: bytes) == keySig)
        }
    }
}
