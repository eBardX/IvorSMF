// © 2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFValidatorCheckerTests {
}

// MARK: -

extension SMFValidatorCheckerTests {
    @Test
    func checkSequence_cleanSequence_noIssues() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var checker = SMFValidator.Checker(sequence: sequence)

        #expect(checker.checkSequence().isEmpty)
    }

    @Test
    func checkSequence_deltaTimeTooLarge() {
        let tBig = SMFEventTime(uintValue: 0x10000000)!             // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(tBig, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var checker = SMFValidator.Checker(sequence: sequence)

        #expect(checker.checkSequence() == [.deltaTimeTooLarge(trackIndex: 0)])
    }

    @Test
    func checkSequence_eventAfterEndOfTrack() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack),
                                      .midi(t0, noteOn)])
        let sequence = makeSequence(tracks: [track])
        var checker = SMFValidator.Checker(sequence: sequence)

        #expect(checker.checkSequence() == [.eventAfterEndOfTrack(trackIndex: 0)])
    }

    @Test
    func checkSequence_invalidTrackCount_format0() {
        let sequence = makeSequence(tracks: [])
        var checker = SMFValidator.Checker(sequence: sequence)

        #expect(checker.checkSequence() == [.invalidTrackCount(trackCount: 0,
                                                               format: .format0)])
    }

    @Test
    func checkSequence_invalidTrackCount_nonFormat0() {
        let sequence = makeSequence(format: .format1, tracks: [])
        var checker = SMFValidator.Checker(sequence: sequence)

        #expect(checker.checkSequence() == [.invalidTrackCount(trackCount: 0,
                                                               format: .format1)])
    }

    @Test
    func checkSequence_missingEndOfTrack() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn)])
        let sequence = makeSequence(tracks: [track])
        var checker = SMFValidator.Checker(sequence: sequence)

        #expect(checker.checkSequence() == [.missingEndOfTrack(trackIndex: 0)])
    }

    @Test
    func checkSequence_multipleIssues_accumulate() {
        let tBig = SMFEventTime(uintValue: 0x10000000)!             // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(tBig, .tempo(tempo))])
        let sequence = makeSequence(tracks: [track])
        var checker = SMFValidator.Checker(sequence: sequence)
        let issues = checker.checkSequence()

        #expect(issues.contains(.missingEndOfTrack(trackIndex: 0)))
        #expect(issues.contains(.deltaTimeTooLarge(trackIndex: 0)))
        #expect(issues.count == 2)
    }

    @Test
    func checkSequence_unencodableText() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let text = SMFText(stringValue: "\u{1F3B5}")!               // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .text(text)),
                                      .meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var checker = SMFValidator.Checker(sequence: sequence)

        #expect(checker.checkSequence() == [.unencodableText(trackIndex: 0)])
    }
}
