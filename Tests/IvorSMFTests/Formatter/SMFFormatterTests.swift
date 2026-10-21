// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFFormatterTests {
}

// MARK: -

extension SMFFormatterTests {
    @Test
    func format_existingEndOfTrack_notDuplicated() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let data = try SMFFormatter().format(makeValidatedSequence(sequence))
        let (reparsed, _) = try SMFParser().parse(data)

        #expect(reparsed.tracks[0].events.filter { $0.isEndOfTrack }.count == 1)
    }

    @Test
    func format_format0() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let noteOff = MIDIChannelMessage(statusByte: 0x80,
                                         dataBytes: [0x3c, 0x40])!  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .tempo(tempo)),
                                      .midi(t0, noteOn),
                                      .midi(t480, noteOff),
                                      .meta(t480, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let data = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(!data.isEmpty)
        #expect(data[0] == 0x4d)
        #expect(data[1] == 0x54)
        #expect(data[2] == 0x68)
        #expect(data[3] == 0x64)
    }

    @Test
    func format_format1_multiTrack() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let noteOff = MIDIChannelMessage(statusByte: 0x80,
                                         dataBytes: [0x3c, 0x40])!  // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t0, .tempo(tempo)),
                                       .meta(t480, .endOfTrack)])
        let track1 = SMFTrack(events: [.midi(t0, noteOn),
                                       .midi(t480, noteOff),
                                       .meta(t480, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [track0, track1])
        let data = try SMFFormatter().format(makeValidatedSequence(sequence))
        let (reparsed, _) = try SMFParser().parse(data)

        #expect(reparsed.format == .format1)
        #expect(reparsed.tracks.count == 2)
        #expect(reparsed.tracks[0].events.count == 2)
        #expect(reparsed.tracks[1].events.count == 3)
    }

    @Test
    func format_headerContainsFormat() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let data = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(data[8] == 0x00)
        #expect(data[9] == 0x00)
    }

    @Test
    func format_highTrackCount_encodedCorrectly() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tracks = Array(repeating: track, count: 0x8000)
        let tickRate = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: tracks)
        let data = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(data[10] == 0x80)
        #expect(data[11] == 0x00)
    }

    @Test
    func format_notValidated_throws() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])

        #expect(throws: SMFFormatter.Error.notValidated) {
            try SMFFormatter().format(sequence)
        }
    }

    @Test
    func format_roundTrip() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let noteOff = MIDIChannelMessage(statusByte: 0x80,
                                         dataBytes: [0x3c, 0x40])!  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .midi(t480, noteOff),
                                      .meta(t480, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let data = try SMFFormatter().format(makeValidatedSequence(sequence))
        let (reparsed, _) = try SMFParser().parse(data)

        #expect(reparsed.format == .format0)
        #expect(reparsed.tracks.count == 1)
        #expect(reparsed.tracks[0].events.count == 3)
    }

    @Test
    func format_systemMessages_roundTrip() throws {
        // Universal SysEx and a song position pointer, written as SMF events
        // and parsed back.
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let volume = MIDIData2Value(uintValue: 12_000)!             // swiftlint:disable:this force_unwrapping
        let position = MIDIData2Value(uintValue: 64)!               // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.sysEx(.zero, SMFSysExMessage(for: .masterVolume(volume))),
                                      .sysEx(t96, SMFSysExMessage(for: .songPosition(position))),
                                      .meta(t96, .endOfTrack)])
        let data = try SMFFormatter().format(makeValidatedSequence(makeSequence(tracks: [track])))
        let (parsed, diagnostics) = try SMFParser().parse(data)

        #expect(diagnostics.isEmpty)
        #expect(parsed.tracks == [track])

        let systemMessages = parsed.tracks[0].events.compactMap { event -> MIDISystemMessage? in
            guard case let .sysEx(_, message) = event
            else { return nil }

            return message.systemMessage
        }

        #expect(systemMessages == [.masterVolume(volume), .songPosition(position)])
    }
}
