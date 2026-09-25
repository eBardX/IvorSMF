// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import IvorSMPTE
import Testing

struct SMFEventTimeTests {
}

// MARK: -

extension SMFEventTimeTests {
    @Test
    func beatTime() {
        let eventTime = SMFEventTime(uintValue: 960)!                   // swiftlint:disable:this force_unwrapping
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping

        #expect(eventTime.beatTime(tickRate) == 2.0)
    }

    @Test
    func init_uintValue() {
        let eventTime = SMFEventTime(uintValue: 0)

        #expect(eventTime != nil)
        #expect(eventTime?.uintValue == 0)

        let eventTime2 = SMFEventTime(uintValue: 0x7fffffff)

        #expect(eventTime2 != nil)
        #expect(eventTime2?.uintValue == 0x7fffffff)
    }

    @Test
    func init_uintValue_invalid() {
        #expect(SMFEventTime(uintValue: 0x80000000) == nil)
    }

    @Test
    func isValid() {
        #expect(SMFEventTime.isValid(0))
        #expect(SMFEventTime.isValid(0x7fffffff))
        #expect(!SMFEventTime.isValid(0x80000000))
    }

    @Test
    func smpteTime() {
        let eventTime = SMFEventTime(uintValue: 100)!                      // swiftlint:disable:this force_unwrapping
        let timeCode = SMFTimeCode(frameRate: .fps25, ticksPerFrame: 4)!   // swiftlint:disable:this force_unwrapping
        let time = eventTime.smpteTime(timeCode)

        #expect(time.frameRate == .fps25)
        #expect(time.hour == 0)
        #expect(time.minute == 0)
        #expect(time.second == 1)
        #expect(time.frame == 0)
        #expect(time.fraction == 0)
    }

    @Test
    func zero() {
        #expect(SMFEventTime.zero.uintValue == 0)
    }
}
