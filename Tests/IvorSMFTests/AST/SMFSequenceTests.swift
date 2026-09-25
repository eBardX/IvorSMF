// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFSequenceTests {
}

// MARK: -

extension SMFSequenceTests {
    @Test
    func equality() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let tickRate = SMFTickRate(uintValue: 480)!                  // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let seq1 = SMFSequence(format: .format0,
                               division: .metrical(tickRate),
                               tracks: [track])
        let seq2 = SMFSequence(format: .format0,
                               division: .metrical(tickRate),
                               tracks: [track])

        #expect(seq1 == seq2)
    }

    @Test
    func equality_ignoresFlags() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let tickRate = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let seq1 = SMFSequence(format: .format0,
                               division: .metrical(tickRate),
                               tracks: [track])
        let seq2 = SMFSequence(format: .format0,
                               division: .metrical(tickRate),
                               tracks: [track],
                               isNormalized: true,
                               isValidated: true)

        #expect(seq1.isNormalized != seq2.isNormalized)
        #expect(seq1.isValidated != seq2.isValidated)
        #expect(seq1 == seq2)
        #expect(seq1.hashValue == seq2.hashValue)
    }

    @Test
    func inequality_differentDivision() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let tickRate96 = SMFTickRate(uintValue: 96)!                // swiftlint:disable:this force_unwrapping
        let tickRate480 = SMFTickRate(uintValue: 480)!              // swiftlint:disable:this force_unwrapping
        let seq1 = SMFSequence(format: .format0,
                               division: .metrical(tickRate96),
                               tracks: [track])
        let seq2 = SMFSequence(format: .format0,
                               division: .metrical(tickRate480),
                               tracks: [track])

        #expect(seq1 != seq2)
    }

    @Test
    func inequality_differentFormat() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track2 = SMFTrack(events: [])
        let seq1 = SMFSequence(format: .format0,
                               division: .metrical(tickRate),
                               tracks: [track1, track2])
        let seq2 = SMFSequence(format: .format1,
                               division: .metrical(tickRate),
                               tracks: [track1, track2])

        #expect(seq1 != seq2)
    }

    @Test
    func inequality_differentTrackContents() {
        let t0 = SMFEventTime(uintValue: 0)!                        // swiftlint:disable:this force_unwrapping
        let t1 = SMFEventTime(uintValue: 96)!                       // swiftlint:disable:this force_unwrapping
        let tickRate = SMFTickRate(uintValue: 96)!                  // swiftlint:disable:this force_unwrapping
        let track1 = SMFTrack(events: [.meta(t0, .endOfTrack)])
        let track2 = SMFTrack(events: [.meta(t1, .endOfTrack)])
        let seq1 = SMFSequence(format: .format0,
                               division: .metrical(tickRate),
                               tracks: [track1])
        let seq2 = SMFSequence(format: .format0,
                               division: .metrical(tickRate),
                               tracks: [track2])

        #expect(seq1 != seq2)
    }

    @Test
    func init_format0() {
        let eventTime = SMFEventTime(uintValue: 0)!                     // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(eventTime, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])

        #expect(sequence.format == .format0)
        #expect(sequence.tracks.count == 1)

        if case let .metrical(tr) = sequence.division {
            #expect(tr.uintValue == 480)
        } else {
            Issue.record("Expected metrical division")
        }
    }

    @Test
    func init_format1() {
        let eventTime = SMFEventTime(uintValue: 0)!                     // swiftlint:disable:this force_unwrapping
        let track1 = SMFTrack(events: [.meta(eventTime, .endOfTrack)])
        let track2 = SMFTrack(events: [.meta(eventTime, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: [track1, track2])

        #expect(sequence.format == .format1)
        #expect(sequence.tracks.count == 2)
    }

    @Test
    func init_format1_highTrackCount() {
        let track = SMFTrack(events: [])
        let tracks = Array(repeating: track, count: 0x8000)
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format1,
                                   division: .metrical(tickRate),
                                   tracks: tracks)

        #expect(sequence.tracks.count == 0x8000)
    }

    @Test
    func init_setsFlagsFalse() {
        let eventTime = SMFEventTime(uintValue: 0)!                     // swiftlint:disable:this force_unwrapping
        let track = SMFTrack(events: [.meta(eventTime, .endOfTrack)])
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping
        let sequence = SMFSequence(format: .format0,
                                   division: .metrical(tickRate),
                                   tracks: [track])

        #expect(sequence.isNormalized == false)
        #expect(sequence.isValidated == false)
    }
}
