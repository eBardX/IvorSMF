// © 2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import IvorSMPTE
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
    func editSequence_conductorRelocation_keepsLaterEndOfTrack() {
        // The tempo track from RP-001’s format 1 example ends at tick 384;
        // moving a tempo at tick 100 into it must not shorten it.
        let t100 = SMFEventTime(uintValue: 100)!                    // swiftlint:disable:this force_unwrapping
        let t384 = SMFEventTime(uintValue: 384)!                    // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 600_000)!                   // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(.zero, .tempo(.default)),
                                       .meta(t384, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(t100, .tempo(tempo)),
                                       .meta(t100, .endOfTrack)])
        let sequence = makeSequence(format: .format1,
                                    tracks: [track0, track1])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedTempo(trackIndex: 1)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .tempo(.default)),
                                                .meta(t100, .tempo(tempo)),
                                                .meta(t384, .endOfTrack)])
    }

    @Test
    func editSequence_deviceNameAfterProgramChange_movesToStart() {
        let deviceName = SMFText(stringValue: "Synth")!             // swiftlint:disable:this force_unwrapping
        let program = MIDIChannelMessage(statusByte: 0xc0,
                                         dataBytes: [0x05])!        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(.zero, program),
                                      .meta(.zero, .deviceName(deviceName)),
                                      .meta(.zero, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedDeviceName(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .deviceName(deviceName)),
                                                .midi(.zero, program),
                                                .meta(.zero, .endOfTrack)])
    }

    @Test
    func editSequence_duplicateEndOfTrack_keepsLatestTick() {
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let t200 = SMFEventTime(uintValue: 200)!                    // swiftlint:disable:this force_unwrapping
        let t500 = SMFEventTime(uintValue: 500)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t96, .endOfTrack),
                                      .midi(t200, noteOn),
                                      .meta(t500, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedEndOfTrack(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.midi(t200, noteOn),
                                                .meta(t500, .endOfTrack)])
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
    func editSequence_escapeDuringOpenSysEx_terminatesMessage() {
        let t10 = SMFEventTime(uintValue: 10)!                      // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.sysEx(.zero, .systemExclusive([0x43, 0x12])),
                                      .sysEx(t10, .escape([0xf8])),
                                      .meta(t10, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.terminatedSysEx(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.sysEx(.zero, .systemExclusive([0x43, 0x12, 0xf7])),
                                                .sysEx(t10, .escape([0xf8])),
                                                .meta(t10, .endOfTrack)])
    }

    @Test
    func editSequence_midiEventBetweenSysExPackets_terminatesAndEscapes() {
        let t10 = SMFEventTime(uintValue: 10)!                      // swiftlint:disable:this force_unwrapping
        let t20 = SMFEventTime(uintValue: 20)!                      // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.sysEx(.zero, .systemExclusive([0x43, 0x12])),
                                      .midi(t10, noteOn),
                                      .sysEx(t20, .continuation([0x00, 0xf7])),
                                      .meta(t20, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.terminatedSysEx(trackIndex: 0),
                            .convertedSysExContinuationToEscape(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.sysEx(.zero, .systemExclusive([0x43, 0x12, 0xf7])),
                                                .midi(t10, noteOn),
                                                .sysEx(t20, .escape([0x00, 0xf7])),
                                                .meta(t20, .endOfTrack)])
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
    func editSequence_multiPacketSysEx_leftUnchanged() {
        // The multi-packet example from RP-001 p.7.
        let t200 = SMFEventTime(uintValue: 200)!                    // swiftlint:disable:this force_unwrapping
        let t300 = SMFEventTime(uintValue: 300)!                    // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.sysEx(.zero, .systemExclusive([0x43, 0x12, 0x00])),
                                      .sysEx(t200, .continuation([0x43, 0x12, 0x00, 0x43, 0x12, 0x00])),
                                      .sysEx(t300, .continuation([0x43, 0x12, 0x00, 0xf7])),
                                      .meta(t300, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes.isEmpty)
        #expect(normalized.tracks == [track])
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
    func editSequence_sequenceNumberAfterMIDIEventAtZero_movesAhead() {
        let seqNum = SMFData2Value(uintValue: 1)!                   // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(.zero, noteOn),
                                      .meta(.zero, .sequenceNumber(seqNum)),
                                      .meta(.zero, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedSequenceNumber(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .sequenceNumber(seqNum)),
                                                .midi(.zero, noteOn),
                                                .meta(.zero, .endOfTrack)])
    }

    @Test
    func editSequence_sequenceNumberMovedToZero_precedesMIDIEventsAtZero() {
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let seqNum = SMFData2Value(uintValue: 1)!                   // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(.zero, noteOn),
                                      .meta(t96, .sequenceNumber(seqNum)),
                                      .meta(t96, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedSequenceNumber(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .sequenceNumber(seqNum)),
                                                .midi(.zero, noteOn),
                                                .meta(t96, .endOfTrack)])
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

    @Test
    func editSequence_sequenceTrackNameNotAtTimeZero_movesToStart() {
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let name = SMFText(stringValue: "Piano")!                   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t96, .sequenceTrackName(name)),
                                      .meta(t96, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedSequenceTrackName(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .sequenceTrackName(name)),
                                                .meta(t96, .endOfTrack)])
    }

    @Test
    func editSequence_smpteOffsetAfterSysEx_movesToStart() {
        let offset = SMPTETime(frameRate: .fps25,
                               hour: 1,
                               minute: 0,
                               second: 0,
                               frame: 0,
                               subframe: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.sysEx(.zero, .systemExclusive([0x7e, 0xf7])),
                                      .meta(.zero, .smpteOffset(offset)),
                                      .meta(.zero, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedSMPTEOffset(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .smpteOffset(offset)),
                                                .sysEx(.zero, .systemExclusive([0x7e, 0xf7])),
                                                .meta(.zero, .endOfTrack)])
    }

    @Test
    func editSequence_smpteOffsetAndSequenceNumberInLaterTrack_moveToTrackZero() {
        let seqNum = SMFData2Value(uintValue: 7)!                   // swiftlint:disable:this force_unwrapping
        let offset = SMPTETime(frameRate: .fps25,
                               hour: 1,
                               minute: 0,
                               second: 0,
                               frame: 0,
                               subframe: 0)!                        // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(.zero, .tempo(.default)),
                                       .meta(.zero, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(.zero, .sequenceNumber(seqNum)),
                                       .meta(.zero, .smpteOffset(offset)),
                                       .meta(.zero, .endOfTrack)])
        let sequence = makeSequence(format: .format1,
                                    tracks: [track0, track1])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.relocatedSequenceNumberToFirstTrack(trackIndex: 1),
                            .relocatedSMPTEOffsetToFirstTrack(trackIndex: 1)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .tempo(.default)),
                                                .meta(.zero, .sequenceNumber(seqNum)),
                                                .meta(.zero, .smpteOffset(offset)),
                                                .meta(.zero, .endOfTrack)])
        #expect(normalized.tracks[1].events == [.meta(.zero, .endOfTrack)])
    }

    @Test
    func editSequence_unterminatedSysExAtEndOfTrack_appendsF7() {
        let track = SMFTrack(events: [.sysEx(.zero, .systemExclusive([0x43, 0x12])),
                                      .meta(.zero, .endOfTrack)])
        let sequence = makeSequence(tracks: [track])
        var editor = SMFNormalizer.Editor(sequence: sequence)
        let (normalized, changes) = editor.editSequence()

        #expect(changes == [.terminatedSysEx(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.sysEx(.zero, .systemExclusive([0x43, 0x12, 0xf7])),
                                                .meta(.zero, .endOfTrack)])
    }
}
