// © 2025–2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFSysExMessageTests {
}

// MARK: -

extension SMFSysExMessageTests {
    @Test
    func dataBytes_escape() {
        let msg = SMFSysExMessage(statusByte: 0xf7,
                                  dataBytes: [0x01, 0x02])

        #expect(msg?.dataBytes == [0x01, 0x02])
    }

    @Test
    func dataBytes_systemExclusive() {
        let msg = SMFSysExMessage(statusByte: 0xf0,
                                  dataBytes: [0x7e, 0xf7])

        #expect(msg?.dataBytes == [0x7e, 0xf7])
    }

    @Test
    func equality() {
        #expect(SMFSysExMessage.escape([0x01]) == .escape([0x01]))
    }

    @Test
    func hashable() {
        let set: Set<SMFSysExMessage> = [.escape([0x01]), .escape([0x01]), .systemExclusive([0x01])]

        #expect(set.count == 2)
    }

    @Test
    func inequality_differentCase() {
        #expect(SMFSysExMessage.escape([0x01]) != .systemExclusive([0x01]))
    }

    @Test
    func init_continuation() {
        let msg = SMFSysExMessage(statusByte: 0xf7,
                                  dataBytes: [0x01, 0x02],
                                  isContinuation: true)

        #expect(msg == .continuation([0x01, 0x02]))
    }

    @Test
    func init_escape() {
        let msg = SMFSysExMessage(statusByte: 0xf7,
                                  dataBytes: [0x01, 0x02])

        #expect(msg != nil)

        if case let .escape(data) = msg {
            #expect(data == [0x01, 0x02])
        } else {
            Issue.record("Expected escape")
        }
    }

    @Test
    func init_invalid_statusByte() {
        #expect(SMFSysExMessage(statusByte: 0x90,
                                dataBytes: []) == nil)
        #expect(SMFSysExMessage(statusByte: 0xff,
                                dataBytes: []) == nil)
    }

    @Test
    func init_systemExclusive() {
        let msg = SMFSysExMessage(statusByte: 0xf0,
                                  dataBytes: [0x7e, 0xf7])

        #expect(msg != nil)

        if case let .systemExclusive(data) = msg {
            #expect(data == [0x7e, 0xf7])
        } else {
            Issue.record("Expected systemExclusive")
        }
    }

    @Test
    func init_systemMessage_realTime_becomesEscape() {
        #expect(SMFSysExMessage(for: .timingClock) == .escape([0xf8]))
    }

    @Test
    func init_systemMessage_songPosition_becomesEscape() {
        let position = MIDIData2Value(uintValue: 0x0101)!           // swiftlint:disable:this force_unwrapping

        #expect(SMFSysExMessage(for: .songPosition(position)) == .escape([0xf2, 0x01, 0x02]))
    }

    @Test
    func init_systemMessage_universalBuilder_becomesSystemExclusive() {
        let volume = MIDIData2Value(uintValue: 16_383)!             // swiftlint:disable:this force_unwrapping

        #expect(SMFSysExMessage(for: .masterVolume(volume)) == .systemExclusive([0x7f, 0x7f, 0x04, 0x01, 0x7f, 0x7f, 0xf7]))
    }

    @Test
    func isOpenEnded() {
        #expect(SMFSysExMessage.systemExclusive([0x43]).isOpenEnded)
        #expect(!SMFSysExMessage.systemExclusive([0x43, 0xf7]).isOpenEnded)
        #expect(SMFSysExMessage.continuation([]).isOpenEnded)
        #expect(!SMFSysExMessage.continuation([0xf7]).isOpenEnded)
        #expect(!SMFSysExMessage.escape([0x43]).isOpenEnded)
    }

    @Test
    func statusByte_continuation() {
        let msg = SMFSysExMessage.continuation([0x01])

        #expect(msg.statusByte == 0xf7)
        #expect(msg.dataBytes == [0x01])
    }

    @Test
    func statusByte_escape() {
        let msg = SMFSysExMessage.escape([0x01])

        #expect(msg.statusByte == 0xf7)
    }

    @Test
    func statusByte_systemExclusive() {
        let msg = SMFSysExMessage.systemExclusive([0x7e, 0xf7])

        #expect(msg.statusByte == 0xf0)
    }

    @Test
    func systemMessage_continuation_isNil() {
        #expect(SMFSysExMessage.continuation([0x43, 0xf7]).systemMessage == nil)
    }

    @Test
    func systemMessage_escape() {
        let position = MIDIData2Value(uintValue: 0x0101)!           // swiftlint:disable:this force_unwrapping

        #expect(SMFSysExMessage.escape([0xf8]).systemMessage == .timingClock)
        #expect(SMFSysExMessage.escape([0xf2, 0x01, 0x02]).systemMessage == .songPosition(position))
    }

    @Test
    func systemMessage_escape_notOneMessage_isNil() {
        #expect(SMFSysExMessage.escape([0xf8, 0xf8]).systemMessage == nil)
        #expect(SMFSysExMessage.escape([0x90, 0x3c, 0x64]).systemMessage == nil)
        #expect(SMFSysExMessage.escape([]).systemMessage == nil)
    }

    @Test
    func systemMessage_roundTrip() {
        let volume = MIDIData2Value(uintValue: 8_192)!              // swiftlint:disable:this force_unwrapping
        let messages: [MIDISystemMessage] = [.masterVolume(volume), .start, .tuneRequest]

        for message in messages {
            #expect(SMFSysExMessage(for: message).systemMessage == message)
        }
    }

    @Test
    func systemMessage_systemExclusive_complete() {
        #expect(SMFSysExMessage.systemExclusive([0x7e, 0x7f, 0x09, 0x01, 0xf7]).systemMessage
                == .systemExclusive([0x7e, 0x7f, 0x09, 0x01, 0xf7]))
    }

    @Test
    func systemMessage_systemExclusive_firstPacket_isNil() {
        #expect(SMFSysExMessage.systemExclusive([0x43, 0x12]).systemMessage == nil)
    }
}
