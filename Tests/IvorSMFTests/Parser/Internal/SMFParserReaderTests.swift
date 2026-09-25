// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
import IvorMIDI
@testable import IvorSMF
import Testing

struct SMFParserReaderTests {
}

// MARK: -

extension SMFParserReaderTests {
    @Test
    func readSequence_chunkLengthClamped_diagnostic() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        // Declares a 10-byte MTrk chunk but supplies only 4 bytes of content.
        bytes += [0x4d, 0x54, 0x72, 0x6b, 0x00, 0x00, 0x00, 0x0a]
        bytes += [0x00, 0xff, 0x2f, 0x00]

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        #expect(sequence.tracks.count == 1)
        #expect(diagnostics.contains {
            if case .chunkLengthClamped = $0 {
                return true
            }

            return false
        })
    }

    @Test
    func readSequence_invalidChunkType_throws() {
        // Chunk id byte 0x80 is not ASCII, so the chunk type cannot be
        // decoded even before the header is located.
        let data = Data([0x80, 0x54, 0x68, 0x64])

        #expect(throws: SMFParser.Error.invalidChunkType("\u{80}Thd")) {
            var reader = SMFParser.Reader(data: data)

            _ = try reader.readSequence()
        }
    }

    @Test
    func readSequence_metaEventLengthClamped_diagnostic() throws {
        // FF 51 04 07 A1 20 FF — a tempo meta-event declaring 4 data bytes
        // (one more than the 3 the type defines). RP-001 (p.7) requires it
        // be recognized as a tempo, ignoring the surplus byte.
        let content: [UInt8] = [0x00, 0xff, 0x51, 0x04, 0x07, 0xa1, 0x20, 0xff, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        if case let .meta(_, .tempo(tempo)) = sequence.tracks[0].events[0] {
            #expect(tempo.uintValue == 500_000)
        } else {
            Issue.record("Expected tempo meta-event")
        }

        #expect(diagnostics.contains(.metaEventLengthClamped(type: 0x51,
                                                             declared: 4,
                                                             expected: 3)))
    }

    @Test
    func readSequence_metaEventLengthInvalid_diagnostic() throws {
        // FF 51 02 07 A1 — a tempo meta-event declaring only 2 of the 3
        // data bytes the type defines. The missing byte cannot be
        // recovered, so the event degrades to `.unknown`.
        let content: [UInt8] = [0x00, 0xff, 0x51, 0x02, 0x07, 0xa1, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        if case let .meta(_, .unknown(typeByte, data)) = sequence.tracks[0].events[0] {
            #expect(typeByte == 0x51)
            #expect(data == [0x07, 0xa1])
        } else {
            Issue.record("Expected unknown meta-event")
        }

        #expect(diagnostics.contains(.metaEventLengthInvalid(type: 0x51,
                                                             declared: 2,
                                                             expected: 3)))
    }

    @Test
    func readSequence_missingHeaderChunk_throws() {
        let data = Data(makeTrackBytes([0x00, 0xff, 0x2f, 0x00]))

        #expect(throws: SMFParser.Error.missingHeaderChunk) {
            var reader = SMFParser.Reader(data: data)

            _ = try reader.readSequence()
        }
    }

    @Test
    func readSequence_runningStatus_appliesAcrossEvents() throws {
        let content: [UInt8] = [0x00, 0x90, 0x3c, 0x64, 0x00, 0x3e, 0x64, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, _) = try reader.readSequence()

        #expect(sequence.tracks[0].events.count == 3)

        if case let .midi(_, message) = sequence.tracks[0].events[1] {
            #expect(message == .noteOn(MIDIChannel(uintValue: 1)!,      // swiftlint:disable:this force_unwrapping
                                       MIDIData1Value(uintValue: 0x3e)!, // swiftlint:disable:this force_unwrapping
                                       MIDIData1Value(uintValue: 0x64)!)) // swiftlint:disable:this force_unwrapping
        } else {
            Issue.record("Expected running-status MIDI event at events[1]")
        }
    }

    @Test
    func readSequence_strayRealTimeByte_diagnostic() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xf8, 0x90, 0x3c, 0x40, 0x00, 0xff, 0x2f, 0x00])

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        #expect(sequence.tracks[0].events.count == 2)
        #expect(diagnostics.contains(.strayRealTimeByteSkipped))
    }

    @Test
    func readSequence_tooManyHeaderChunks_throws() {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += [0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x00]

        #expect(throws: SMFParser.Error.tooManyHeaderChunks) {
            var reader = SMFParser.Reader(data: Data(bytes))

            _ = try reader.readSequence()
        }
    }

    @Test
    func readSequence_trackCountMismatch_diagnostic() throws {
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0002, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        #expect(sequence.tracks.count == 1)
        #expect(diagnostics.contains(.trackCountMismatch(declared: 2, actual: 1)))
    }

    @Test
    func readSequence_truncatedEvent_keepsPriorEvents() throws {
        // The MTrk chunk ends after the status byte of a second note-on, so
        // that event's data bytes lie beyond the chunk. The track ends there,
        // keeping the complete note-on that preceded it, and the skipped
        // event is reported.
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0x90, 0x3c, 0x40, 0x00, 0x90])

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        #expect(sequence.tracks.count == 1)
        #expect(sequence.tracks[0].events.count == 1)
        #expect(diagnostics == [.truncatedEventSkipped])

        if case let .midi(_, message) = sequence.tracks[0].events[0] {
            #expect(message == .noteOn(MIDIChannel(uintValue: 1)!,      // swiftlint:disable:this force_unwrapping
                                       MIDIData1Value(uintValue: 0x3c)!, // swiftlint:disable:this force_unwrapping
                                       MIDIData1Value(uintValue: 0x40)!)) // swiftlint:disable:this force_unwrapping
        } else {
            Issue.record("Expected MIDI event at events[0]")
        }
    }

    @Test
    func readSequence_truncatedEvent_laterTracksKept() throws {
        // The first MTrk chunk ends partway through a note-on; the track
        // that follows it must still be parsed rather than discarded.
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0002, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0x90, 0x3c, 0x40, 0x00, 0x90])
        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        #expect(sequence.tracks.count == 2)
        #expect(sequence.tracks[0].events.count == 1)
        #expect(sequence.tracks[1].events == [.meta(.zero, .endOfTrack)])
        #expect(diagnostics == [.truncatedEventSkipped])
    }

    @Test
    func readSequence_unknownChunkType_ignored() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        // An unrecognized "XTRA" chunk between the header and the track
        // chunk must be skipped without affecting the parsed track count.
        bytes += [0x58, 0x54, 0x52, 0x41, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00]
        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        #expect(sequence.tracks.count == 1)
        #expect(!diagnostics.contains {
            if case .trackCountMismatch = $0 {
                return true
            }

            return false
        })
    }

    @Test
    func readSequence_variableLengthQuantityClamped_diagnostic() throws {
        // A 5-byte delta-time (FF FF FF FF 7F) encodes a value larger than
        // the 0x0fffffff maximum defined by RP-001 (p.2).
        let content: [UInt8] = [0xff, 0xff, 0xff, 0xff, 0x7f, 0x90, 0x3c, 0x40, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        var reader = SMFParser.Reader(data: Data(bytes))
        let (sequence, diagnostics) = try reader.readSequence()

        if case let .midi(t, _) = sequence.tracks[0].events[0] {
            #expect(t.uintValue == 0x0fffffff)
        } else {
            Issue.record("Expected MIDI event at events[0]")
        }

        #expect(diagnostics.contains(.variableLengthQuantityClamped))
    }
}
