// © 2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFNormalizerTests {
}

// MARK: -

extension SMFNormalizerTests {
    @Test
    func normalize_alreadyCanonical_reportsNoChange() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes.isEmpty)
        #expect(normalized.tracks == [track])
        #expect(normalized.isNormalized == true)
    }

    @Test
    func normalize_alreadyNormalized_isIdempotent() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let normalizer = SMFNormalizer()
        let (once, _) = normalizer.normalize(sequence)
        let (twice, changes) = normalizer.normalize(once)

        #expect(twice == once)
        #expect(twice.isNormalized == true)
        #expect(changes.isEmpty)
    }

    @Test
    func normalize_emptyTrack_insertsEndOfTrackAtZero() {
        let track = SMFTrack(events: [])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes == [.insertedEndOfTrack(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(.zero, .endOfTrack)])
    }

    @Test
    func normalize_format0ManyTracks_coercesToFormat1() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track0, track1])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(normalized.format == .format1)
        #expect(changes.contains(.coercedFormat(from: .format0, to: .format1)))
        #expect(changes[0].trackIndex == nil)
    }

    @Test
    func normalize_missingEndOfTrack_insertsAtMaxTick() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let noteOff = MIDIChannelMessage(statusByte: 0x80,
                                         dataBytes: [0x3c, 0x40])!  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.midi(t0, noteOn),
                                      .midi(t480, noteOff)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes == [.insertedEndOfTrack(trackIndex: 0)])
        #expect(changes[0].trackIndex == 0)
        #expect(!changes[0].message.isEmpty)

        let events = normalized.tracks[0].events

        #expect(events.count == 3)
        #expect(events[0] == .midi(t0, noteOn))
        #expect(events[1] == .midi(t480, noteOff))
        #expect(events[2] == .meta(t480, .endOfTrack))
    }

    @Test
    func normalize_normalizedSequence_hasNoIssues() throws {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t480, .endOfTrack),
                                       .midi(t0, noteOn)])
        let track1 = SMFTrack(events: [])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [track0, track1])
        let (normalized, _) = SMFNormalizer().normalize(sequence)
        let (_, issues) = try SMFValidator().validate(normalized)

        #expect(issues.isEmpty)
    }

    @Test
    func normalize_prematureEndOfTrack_relocatesToEnd() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack),
                                      .midi(t96, noteOn)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes == [.relocatedEndOfTrack(trackIndex: 0)])

        let events = normalized.tracks[0].events

        #expect(events == [.midi(t96, noteOn), .meta(t96, .endOfTrack)])
    }

    @Test
    func normalize_preservesAllMusicalEvents() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let t192 = SMFEventTime(uintValue: 192)!                    // swiftlint:disable:this force_unwrapping
        let noteOn = MIDIChannelMessage(statusByte: 0x90,
                                        dataBytes: [0x3c, 0x64])!   // swiftlint:disable:this force_unwrapping
        let noteOff = MIDIChannelMessage(statusByte: 0x80,
                                         dataBytes: [0x3c, 0x40])!  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack),   // premature EOT
                                      .midi(t0, noteOn),
                                      .midi(t96, noteOff),
                                      .meta(t192, .endOfTrack)]) // duplicate EOT
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes == [.relocatedEndOfTrack(trackIndex: 0)])

        let events = normalized.tracks[0].events

        #expect(events.filter { !$0.isEndOfTrack }.count == 2)
        #expect(events.contains(.midi(t0, noteOn)))
        #expect(events.contains(.midi(t96, noteOff)))
        #expect(events.filter(\.isEndOfTrack).count == 1)
        #expect(events.last?.isEndOfTrack == true)
        #expect(events.last?.eventTime == t96)
    }

    @Test
    func normalize_sequenceNumberNotAtTimeZero_resetsToZero() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t96 = SMFEventTime(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let seqNum = SMFData2Value(uintValue: 1)!                   // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t96, .sequenceNumber(seqNum)),
                                      .meta(t96, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes == [.relocatedSequenceNumber(trackIndex: 0)])
        #expect(normalized.tracks[0].events == [.meta(t0, .sequenceNumber(seqNum)),
                                                .meta(t96, .endOfTrack)])
    }

    @Test
    func normalize_setsIsNormalized() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])

        #expect(sequence.isNormalized == false)
        #expect(SMFNormalizer().normalize(sequence).0.isNormalized == true)
    }

    @Test
    func normalize_tempoAndTimeSignatureSameTrack_movesToTrackZero() {
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
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [track0, track1])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes.contains(.relocatedTempo(trackIndex: 1)))
        #expect(changes.contains(.relocatedTimeSignature(trackIndex: 1)))
        #expect(changes.count == 2)
        #expect(normalized.tracks[0].events == [.meta(t480, .tempo(tempo)),
                                                .meta(t480, .timeSignature(timeSig)),
                                                .meta(t480, .endOfTrack)])
        #expect(normalized.tracks[1].events == [.meta(t480, .endOfTrack)])
    }

    @Test
    func normalize_tempoInNonTempoTrack_movesToTrackZero() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t480 = SMFEventTime(uintValue: 480)!                    // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(t480, .tempo(tempo)),
                                       .meta(t480, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [track0, track1])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes == [.relocatedTempo(trackIndex: 1)])
        #expect(normalized.tracks[0].events == [.meta(t480, .tempo(tempo)),
                                                .meta(t480, .endOfTrack)])
        #expect(normalized.tracks[1].events == [.meta(t480, .endOfTrack)])
    }

    @Test
    func normalize_timeSignatureInNonTempoTrack_movesToTrackZero() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let timeSig = SMFTimeSignature(numerator: 4,
                                       denominator: 2,
                                       clockRate: 24,
                                       beatRate: 8)!                // swiftlint:disable:this force_unwrapping
        let track0 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track1 = SMFTrack(events: [.meta(t0, .timeSignature(timeSig)),
                                       .meta(t0, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [track0, track1])
        let (normalized, changes) = SMFNormalizer().normalize(sequence)

        #expect(changes == [.relocatedTimeSignature(trackIndex: 1)])
        #expect(normalized.tracks[0].events == [.meta(t0, .timeSignature(timeSig)),
                                                .meta(t0, .endOfTrack)])
        #expect(normalized.tracks[1].events == [.meta(t0, .endOfTrack)])
    }
}
