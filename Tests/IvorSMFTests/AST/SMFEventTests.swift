// © 2025–2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFEventTests {
}

// MARK: -

extension SMFEventTests {
    @Test
    func equality_meta() {
        let t = SMFEventTime(uintValue: 0)!                         // swiftlint:disable:this force_unwrapping

        #expect(SMFEvent.meta(t, .endOfTrack) == .meta(t, .endOfTrack))
    }

    @Test
    func equality_midi() {
        let t = SMFEventTime(uintValue: 96)!                        // swiftlint:disable:this force_unwrapping
        let msg = MIDIChannelMessage(statusByte: 0x90,
                                     dataBytes: [0x3c, 0x64])!      // swiftlint:disable:this force_unwrapping

        #expect(SMFEvent.midi(t, msg) == .midi(t, msg))
    }

    @Test
    func equality_sysEx() {
        let t = SMFEventTime(uintValue: 0)!                         // swiftlint:disable:this force_unwrapping
        let msg = SMFSysExMessage(statusByte: 0xf7,
                                  dataBytes: [0x01])!               // swiftlint:disable:this force_unwrapping

        #expect(SMFEvent.sysEx(t, msg) == .sysEx(t, msg))
    }

    @Test
    func eventTime_meta() {
        let eventTime = SMFEventTime(uintValue: 100)!               // swiftlint:disable:this force_unwrapping
        let event = SMFEvent.meta(eventTime, .endOfTrack)

        #expect(event.eventTime.uintValue == 100)
    }

    @Test
    func eventTime_midi() {
        let eventTime = SMFEventTime(uintValue: 200)!               // swiftlint:disable:this force_unwrapping
        let msg = MIDIChannelMessage(statusByte: 0x90,
                                     dataBytes: [0x3c, 0x64])!      // swiftlint:disable:this force_unwrapping
        let event = SMFEvent.midi(eventTime, msg)

        #expect(event.eventTime.uintValue == 200)
    }

    @Test
    func eventTime_sysEx() {
        let eventTime = SMFEventTime(uintValue: 300)!               // swiftlint:disable:this force_unwrapping
        let msg = SMFSysExMessage(statusByte: 0xf0,
                                  dataBytes: [0x7e, 0xf7])!         // swiftlint:disable:this force_unwrapping
        let event = SMFEvent.sysEx(eventTime, msg)

        #expect(event.eventTime.uintValue == 300)
    }

    @Test
    func hashable() {
        let t = SMFEventTime(uintValue: 0)!                         // swiftlint:disable:this force_unwrapping
        let eot = SMFEvent.meta(t, .endOfTrack)
        let set: Set<SMFEvent> = [eot, eot]

        #expect(set.count == 1)
    }

    @Test
    func inequality_differentMessage() {
        let t = SMFEventTime(uintValue: 0)!                         // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping

        #expect(SMFEvent.meta(t, .endOfTrack) != .meta(t, .tempo(tempo)))
    }

    @Test
    func inequality_differentTime() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t1 = SMFEventTime(uintValue: 1)!                        // swiftlint:disable:this force_unwrapping

        #expect(SMFEvent.meta(t0, .endOfTrack) != .meta(t1, .endOfTrack))
    }

    @Test
    func isEndOfTrack() {
        let t = SMFEventTime(uintValue: 0)!                         // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping

        #expect(SMFEvent.meta(t, .endOfTrack).isEndOfTrack)
        #expect(!SMFEvent.meta(t, .tempo(tempo)).isEndOfTrack)

        let msg = MIDIChannelMessage(statusByte: 0x90,
                                     dataBytes: [0x3c, 0x64])!      // swiftlint:disable:this force_unwrapping

        #expect(!SMFEvent.midi(t, msg).isEndOfTrack)
    }
}
