// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import IvorSMPTE
import Testing

struct SMPTETimeSMFTests {
}

// MARK: -

extension SMPTETimeSMFTests {
    @Test
    func bytesValue() {
        let time = SMPTETime(frameRate: .fps24,
                             hour: 1,
                             minute: 2,
                             second: 3,
                             frame: 4,
                             fraction: 5)

        #expect(time?.bytesValue == [0x01, 0x02, 0x03, 0x04, 0x05])
    }

    @Test
    func bytesValue_fps25() {
        let time = SMPTETime(frameRate: .fps25,
                             hour: 0,
                             minute: 0,
                             second: 0,
                             frame: 0,
                             fraction: 0)

        #expect(time?.bytesValue == [0x20, 0x00, 0x00, 0x00, 0x00])
    }

    @Test
    func bytesValue_fps2997() {
        let time = SMPTETime(frameRate: .fps2997,
                             hour: 0,
                             minute: 0,
                             second: 0,
                             frame: 0,
                             fraction: 0)

        #expect(time?.bytesValue == [0x40, 0x00, 0x00, 0x00, 0x00])
    }

    @Test
    func bytesValue_fps30() {
        let time = SMPTETime(frameRate: .fps30,
                             hour: 0,
                             minute: 0,
                             second: 0,
                             frame: 0,
                             fraction: 0)

        #expect(time?.bytesValue == [0x60, 0x00, 0x00, 0x00, 0x00])
    }

    @Test
    func init_bytesValue() {
        let time = SMPTETime(bytesValue: [0x01, 0x02, 0x03, 0x04, 0x05])

        #expect(time != nil)
        #expect(time?.frameRate == .fps24)
        #expect(time?.hour == 1)
        #expect(time?.minute == 2)
        #expect(time?.second == 3)
        #expect(time?.frame == 4)
        #expect(time?.fraction == 5)
    }

    @Test
    func init_bytesValue_fps25() {
        let time = SMPTETime(bytesValue: [0x20, 0x00, 0x00, 0x00, 0x00])

        #expect(time != nil)
        #expect(time?.frameRate == .fps25)
    }

    @Test
    func init_bytesValue_fps2997() {
        let time = SMPTETime(bytesValue: [0x40, 0x00, 0x00, 0x00, 0x00])

        #expect(time != nil)
        #expect(time?.frameRate == .fps2997)
    }

    @Test
    func init_bytesValue_fps30() {
        let time = SMPTETime(bytesValue: [0x60, 0x00, 0x00, 0x00, 0x00])

        #expect(time != nil)
        #expect(time?.frameRate == .fps30)
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMPTETime(bytesValue: []) == nil)
        #expect(SMPTETime(bytesValue: [0x00, 0x00, 0x00, 0x00]) == nil)
        #expect(SMPTETime(bytesValue: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]) == nil)
    }

    @Test
    func init_bytesValue_invalidFrameRate() {
        #expect(SMPTETime(bytesValue: [0x80, 0x00, 0x00, 0x00, 0x00]) == nil)
    }

    @Test
    func roundTrip() {
        let time = SMPTETime(frameRate: .fps25,
                             hour: 10,
                             minute: 30,
                             second: 45,
                             frame: 20,
                             fraction: 50)

        let bytes = time?.bytesValue

        #expect(bytes != nil)

        let roundTripped = bytes.flatMap { SMPTETime(bytesValue: $0) }

        #expect(roundTripped?.frameRate == .fps25)
        #expect(roundTripped?.hour == 10)
        #expect(roundTripped?.minute == 30)
        #expect(roundTripped?.second == 45)
        #expect(roundTripped?.frame == 20)
        #expect(roundTripped?.fraction == 50)
    }
}
