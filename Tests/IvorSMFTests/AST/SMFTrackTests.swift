// © 2025–2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFTrackTests {
}

// MARK: -

extension SMFTrackTests {
    @Test
    func equality() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track2 = SMFTrack(events: [.meta(t0, .endOfTrack)])

        #expect(track1 == track2)
    }

    @Test
    func events() {
        let eventTime = SMFEventTime(uintValue: 0)!                 // swiftlint:disable:this force_unwrapping
        let events: [SMFEvent] = [.meta(eventTime, .endOfTrack)]
        let track = SMFTrack(events: events)

        #expect(track.events.count == 1)
        #expect(track.events[0].eventTime.uintValue == 0)
    }

    @Test
    func events_multiple() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let events: [SMFEvent] = [.midi(t0, noteOn),
                                  .meta(t480, .endOfTrack)]
        let track = SMFTrack(events: events)

        #expect(track.events.count == 2)
    }

    @Test
    func events_unsortedInput_sortsByTime() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let noteOff = MIDIChannelMessage(statusByte: 0x80,
                                         dataBytes: [0x3c, 0x40])!  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t480, .endOfTrack),
                                      .midi(t0, noteOn),
                                      .midi(t96, noteOff)])

        #expect(track.events == [.midi(t0, noteOn),
                                 .midi(t96, noteOff),
                                 .meta(t480, .endOfTrack)])
    }

    @Test
    func hashable() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track2 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let set: Set<SMFTrack> = [track1, track2]

        #expect(set.count == 1)
    }

    @Test
    func inequality_differentEvents() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track2 = SMFTrack(events: [.meta(t96, .endOfTrack)])

        #expect(track1 != track2)
    }
}
