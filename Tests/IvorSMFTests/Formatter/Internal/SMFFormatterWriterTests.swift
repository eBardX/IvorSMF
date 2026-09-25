// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFFormatterWriterTests {
}

// MARK: -

extension SMFFormatterWriterTests {
    @Test
    func writeSequence_callsAreIndependent() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var writer = SMFFormatter.Writer(sequence: sequence)
        let first = writer.writeSequence()
        let second = writer.writeSequence()

        #expect(first == second)
    }

    @Test
    func writeSequence_deltaTime_encodesMultiByteVarlen() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t200 = SMFEventTime(uintValue: 200)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .meta(t200, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var writer = SMFFormatter.Writer(sequence: sequence)
        let bytes = [UInt8](writer.writeSequence())

        // MThd (14 bytes) + MTrk header (8 bytes) = 22; the note-on event
        // is 4 bytes, then delta 200 encodes as the 2-byte VLQ 0x81 0x48.
        #expect(Array(bytes[22..<26]) == [0x00, 0x90, 0x3c, 0x64])
        #expect(Array(bytes[26..<28]) == [0x81, 0x48])
    }

    @Test
    func writeSequence_metaEvent_resetsRunningStatus() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let text = SMFText(stringValue: "x")!                       // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .meta(t0, .marker(text)),
                                      .midi(t0, noteOn),
                                      .meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var writer = SMFFormatter.Writer(sequence: sequence)
        let bytes = [UInt8](writer.writeSequence())

        // Both note-on events re-emit their status byte because the
        // intervening marker meta-event clears the running status.
        #expect(Array(bytes[22..<26]) == [0x00, 0x90, 0x3c, 0x64])
        #expect(Array(bytes[26..<30]) == [0x00, 0xff, 0x06, 0x01])
        #expect(bytes[30] == 0x78)
        #expect(Array(bytes[31..<35]) == [0x00, 0x90, 0x3c, 0x64])
    }

    @Test
    func writeSequence_midi_omitsRepeatedStatusByte() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOnA = MIDIChannelMessage(statusByte: 0x90,
                                         dataBytes: [0x3c, 0x64])!  // swiftlint:disable:this force_unwrapping
        let noteOnB = MIDIChannelMessage(statusByte: 0x90,
                                         dataBytes: [0x3e, 0x50])!  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOnA),
                                      .midi(t0, noteOnB),
                                      .meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var writer = SMFFormatter.Writer(sequence: sequence)
        let bytes = [UInt8](writer.writeSequence())

        #expect(Array(bytes[22..<26]) == [0x00, 0x90, 0x3c, 0x64])
        #expect(Array(bytes[26..<29]) == [0x00, 0x3e, 0x50])
    }

    @Test
    func writeSequence_sysEx_resetsRunningStatus() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let sysEx = SMFSysExMessage(statusByte: 0xf0,
                                    dataBytes: [0x7e, 0xf7])!        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .sysEx(t0, sysEx),
                                      .midi(t0, noteOn),
                                      .meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var writer = SMFFormatter.Writer(sequence: sequence)
        let bytes = [UInt8](writer.writeSequence())

        #expect(Array(bytes[22..<26]) == [0x00, 0x90, 0x3c, 0x64])
        #expect(Array(bytes[26..<30]) == [0x00, 0xf0, 0x02, 0x7e])
        #expect(bytes[30] == 0xf7)
        #expect(Array(bytes[31..<35]) == [0x00, 0x90, 0x3c, 0x64])
    }

    @Test
    func writeSequence_trackChunkLength_matchesContentByteCount() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var writer = SMFFormatter.Writer(sequence: sequence)
        let bytes = [UInt8](writer.writeSequence())

        // The MTrk chunk length is a 4-byte big-endian count of the 4
        // End-of-Track bytes that follow (00 ff 2f 00).
        #expect(Array(bytes[18..<22]) == [0x00, 0x00, 0x00, 0x04])
        #expect(Array(bytes[22..<26]) == [0x00, 0xff, 0x2f, 0x00])
    }
}
