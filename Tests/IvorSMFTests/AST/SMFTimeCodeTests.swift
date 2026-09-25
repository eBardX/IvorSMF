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
    func init_bytesValue_zeroTicksPerFrame() {
        #expect(SMFTimeCode(bytesValue: [0xe8, 0x00]) == nil)
    }

    @Test
    func init_invalid_ticksPerFrame() {
        #expect(SMFTimeCode(frameRate: .fps24, ticksPerFrame: 0) == nil)
        #expect(SMFTimeCode(frameRate: .fps24, ticksPerFrame: 256) == nil)
    }

    @Test(arguments: [SMPTEFrameRate.fps23976, .fps2997NonDrop, .fps50, .fps5994, .fps5994NonDrop, .fps60])
    func init_invalid_unsupportedFrameRate(frameRate: SMPTEFrameRate) {
        #expect(SMFTimeCode(frameRate: frameRate, ticksPerFrame: 4) == nil)
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
        let tc1 = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 1)

        #expect(tc1?.ticksPerFrame == 1)

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

    @Test(arguments: SMPTEFrameRate.allCases)
    func supports(frameRate: SMPTEFrameRate) {
        let expected: Set<SMPTEFrameRate> = [.fps24, .fps25, .fps2997, .fps30]

        #expect(SMFTimeCode.supports(frameRate) == expected.contains(frameRate))
    }

    // The timecode division and the SMPTE Offset meta-event encode frame
    // rates separately, so this checks that `supports(_:)` holds for both.
    @Test(arguments: SMPTEFrameRate.allCases)
    func supports_matchesSMPTEOffsetEncoding(frameRate: SMPTEFrameRate) throws {
        let time = try #require(SMPTETime(frameRate: frameRate,
                                          hour: 1,
                                          minute: 0,
                                          second: 0,
                                          frame: 0,
                                          fraction: 0))

        #expect(SMFTimeCode.supports(frameRate) == (time.bytesValue != nil))
    }
}
