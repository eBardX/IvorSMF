// © 2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFValidatorTests {
}

// MARK: -

extension SMFValidatorTests {
    @Test
    func validate_alreadyValidated_returnsUnchanged() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track],
                                   isNormalized: true,
                                   isValidated: true)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(validated == sequence)
        #expect(validated.isValidated == true)
        #expect(issues.isEmpty)
    }

    @Test
    func validate_cleanSequence_noIssues() throws {
        let (parsed, _) = try SMFParser().parse(makeFormat0Data())
        let sequence = SMFSequence(format: parsed.format,
                                   division: parsed.division,
                                   tracks: parsed.tracks,
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues.isEmpty)
        #expect(validated.isValidated == true)
    }

    @Test
    func validate_deltaTimeTooLarge() throws {
        let tBig = SMFEventTime(uintValue: 0x10000000)!           // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(tBig, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues == [.deltaTimeTooLarge(trackIndex: 0)])
        #expect(validated.isValidated == false)
    }

    @Test
    func validate_eventAfterEndOfTrack() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack),
                                      .midi(t0, noteOn)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues == [.eventAfterEndOfTrack(trackIndex: 0)])
        #expect(!issues[0].message.isEmpty)
        #expect(validated.isValidated == false)
    }

    @Test
    func validate_invalidTrackCount() throws {
        let tickRate = SMFTickRate(uintValue: 96)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues == [.invalidTrackCount(trackCount: 0,
                                              format: .format0)])
        #expect(validated.isValidated == false)
    }

    @Test
    func validate_invalidTrackCount_nonFormat0() throws {
        let tickRate = SMFTickRate(uintValue: 96)!                 // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues == [.invalidTrackCount(trackCount: 0,
                                              format: .format1)])
        #expect(validated.isValidated == false)
    }

    @Test
    func validate_missingEndOfTrack() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues == [.missingEndOfTrack(trackIndex: 0)])
        #expect(validated.isValidated == false)
    }

    @Test
    func validate_multipleIssues_accumulate() throws {
        let tBig = SMFEventTime(uintValue: 0x10000000)!             // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(tBig, .tempo(tempo))])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues.contains(.missingEndOfTrack(trackIndex: 0)))
        #expect(issues.contains(.deltaTimeTooLarge(trackIndex: 0)))
        #expect(issues.count == 2)
        #expect(validated.isValidated == false)
    }

    @Test
    func validate_notNormalized_throws() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])

        #expect(throws: SMFValidator.Error.notNormalized) {
            try SMFValidator().validate(sequence)
        }
    }

    @Test
    func validate_tempoInTrack0_format1_noIssue() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t0, .tempo(tempo)),
                                       .meta(t0, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [track0, track1],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues.isEmpty)
        #expect(validated.isValidated == true)
    }

    @Test
    func validate_unencodableText() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let text = SMFText(stringValue: "\u{1F3B5}")!               // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .text(text)),
                                      .meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track],
                                   isNormalized: true,
                                   isValidated: false)
        let (validated, issues) = try SMFValidator().validate(sequence)

        #expect(issues == [.unencodableText(trackIndex: 0)])
        #expect(validated.isValidated == false)
    }
}
