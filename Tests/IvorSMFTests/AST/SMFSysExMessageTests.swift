// © 2025–2026 John Gary Pusey (see LICENSE.md)

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
    func statusByte_escape() {
        let msg = SMFSysExMessage.escape([0x01])

        #expect(msg.statusByte == 0xf7)
    }

    @Test
    func statusByte_systemExclusive() {
        let msg = SMFSysExMessage.systemExclusive([0x7e, 0xf7])

        #expect(msg.statusByte == 0xf0)
    }
}
