// © 2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFNormalizerEditorTests {
}

// MARK: -

extension SMFNormalizerEditorTests {
    @Test
    func editSequence_alreadyCanonical_reportsNoChange() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes.isEmpty)
        #expect(normalized.tracks == [track])
    }

    @Test
    func editSequence_coercesFormat0MultiTrackToFormat1() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track0, track1])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(normalized.format == .format1)
        #expect(changes.contains(.coercedFormat(from: .format0, to: .format1)))
    }

    @Test
    func editSequence_emptyTrack_insertsEndOfTrackAtZero() {
        let track = SMFTrack(events: [])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.insertedEndOfTrack(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .endOfTrack)])
    }

    @Test
    func editSequence_missingEndOfTrack_insertsAtMaxTick() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let noteOff = MIDIChannelMessage(statusByte: 0x80,
                                         dataBytes: [0x3c, 0x40])!  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .midi(t480, noteOff)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.insertedEndOfTrack(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.midi(t0, noteOn),
                                                .midi(t480, noteOff),
                                                .meta(t480, .endOfTrack)])
    }

    @Test
    func editSequence_prematureEndOfTrack_relocatesToEnd() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack),
                                      .midi(t96, noteOn)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedEndOfTrack(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.midi(t96, noteOn),
                                                .meta(t96, .endOfTrack)])
    }

    @Test
    func editSequence_relocatesConductorEventsToTrackZero() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping
        let timeSig = SMFTimeSignature(numerator: 4,
                                       denominator: 2,
                                       clockRate: 24,
                                       beatRate: 8)!                // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(t480, .tempo(tempo)),
                                       .meta(t480, .timeSignature(timeSig)),
                                       .meta(t480, .endOfTrack)])
        let sequence = makeSequence(format: .format1,
                                    tracks: [track0, track1])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes.contains(.relocatedTempo(trackIndex: 1)))
        #expect(changes.contains(.relocatedTimeSignature(trackIndex: 1)))
        #expect(normalized.tracks[0].events == [.meta(t480, .tempo(tempo)),
                                                .meta(t480, .timeSignature(timeSig)),
                                                .meta(t480, .endOfTrack)])
        #expect(normalized.tracks[1].events == [.meta(t480, .endOfTrack)])
    }

    @Test
    func editSequence_returnsIsNormalizedTrue() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, _) = editor.editSequence()

        #expect(normalized.isNormalized == true)
        #expect(normalized.isValidated == false)
    }

    @Test
    func editSequence_sequenceNumberNotAtTimeZero_resetsToZero() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let seqNum = SMFData2Value(uintValue: 1)!                   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t96, .sequenceNumber(seqNum)),
                                      .meta(t96, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedSequenceNumber(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(t0, .sequenceNumber(seqNum)),
                                                .meta(t96, .endOfTrack)])
    }
}
