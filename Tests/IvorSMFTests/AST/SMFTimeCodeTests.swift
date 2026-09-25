// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import IvorSMPTE
import Testing

struct SMFTimeCodeTests {
}

// MARK: -

extension SMFTimeCodeTests {
    @Test
    func bytesValue() {
        let tc = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)

        #expect(tc?.bytesValue == [0xe8, 0x04])
    }

    @Test
    func bytesValue_fps25() {
        let tc = SMFTimeCode(frameRate: .fps25, ticksPerFrame: 40)

        #expect(tc?.bytesValue == [0xe7, 40])
    }

    @Test
    func bytesValue_fps2997() {
        let tc = SMFTimeCode(frameRate: .fps2997, ticksPerFrame: 4)

        #expect(tc?.bytesValue == [0xe3, 0x04])
    }

    @Test
    func bytesValue_fps30() {
        let tc = SMFTimeCode(frameRate: .fps30, ticksPerFrame: 4)

        #expect(tc?.bytesValue == [0xe2, 0x04])
    }

    @Test
    func equality() {
        let tc1 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)!    // swiftlint:disable:this force_unwrapping
        let tc2 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)!    // swiftlint:disable:this force_unwrapping

        #expect(tc1 == tc2)
    }

    @Test
    func hashable() {
        let tc1 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)!    // swiftlint:disable:this force_unwrapping
        let tc2 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)!    // swiftlint:disable:this force_unwrapping
        let set: Set<SMFTimeCode> = [tc1, tc2]

        #expect(set.count == 1)
    }

    @Test
    func inequality_differentTicksPerFrame() {
        let tc1 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)!    // swiftlint:disable:this force_unwrapping
        let tc2 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 5)!    // swiftlint:disable:this force_unwrapping

        #expect(tc1 != tc2)
    }

    @Test
    func init_bytesValue() {
        let tc = SMFTimeCode(bytesValue: [0xe8, 0x04])

        #expect(tc != nil)
        #expect(tc?.frameRate == .fps24)
        #expect(tc?.ticksPerFrame == 4)
    }

    @Test
    func init_bytesValue_fps25() {
        let tc = SMFTimeCode(bytesValue: [0xe7, 40])

        #expect(tc != nil)
        #expect(tc?.frameRate == .fps25)
        #expect(tc?.ticksPerFrame == 40)
    }

    @Test
    func init_bytesValue_fps2997() {
        let tc = SMFTimeCode(bytesValue: [0xe3, 0x04])

        #expect(tc != nil)
        #expect(tc?.frameRate == .fps2997)
    }

    @Test
    func init_bytesValue_fps30() {
        let tc = SMFTimeCode(bytesValue: [0xe2, 0x04])

        #expect(tc != nil)
        #expect(tc?.frameRate == .fps30)
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMFTimeCode(bytesValue: []) == nil)
        #expect(SMFTimeCode(bytesValue: [0xe8]) == nil)
        #expect(SMFTimeCode(bytesValue: [0xe8, 0x04, 0x00]) == nil)
    }

    @Test
    func init_bytesValue_invalidFrameRate() {
        #expect(SMFTimeCode(bytesValue: [0x00, 0x04]) == nil)
        #expect(SMFTimeCode(bytesValue: [0xe0, 0x04]) == nil)
    }

    @Test
    func init_invalid_ticksPerFrame() {
        #expect(SMFTimeCode(frameRate: .fps24, ticksPerFrame: 256) == nil)
    }

    @Test
    func init_validValues() {
        let tc = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)

        #expect(tc != nil)
        #expect(tc?.frameRate == .fps24)
        #expect(tc?.ticksPerFrame == 4)
    }

    @Test
    func init_validValues_ticksPerFrameBoundaries() {
        let tc0 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 0)

        #expect(tc0?.ticksPerFrame == 0)

        let tc255 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 255)

        #expect(tc255?.ticksPerFrame == 255)
    }

    @Test
    func roundTrip() {
        let tc = SMFTimeCode(frameRate: .fps25, ticksPerFrame: 40)
        let bytes = tc?.bytesValue

        #expect(bytes != nil)

        let roundTripped = bytes.flatMap { SMFTimeCode(bytesValue: $0) }

        #expect(roundTripped?.frameRate == .fps25)
        #expect(roundTripped?.ticksPerFrame == 40)
    }
}
