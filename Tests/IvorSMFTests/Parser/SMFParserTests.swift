// © 2025–2026 John Gary Pusey (see LICENSE.md)

// swiftlint:disable file_length

import Foundation
@testable import IvorSMF
import IvorSMPTE
import Testing

struct SMFParserTests {
}

// MARK: -

extension SMFParserTests {
    @Test
    func parse_emptyLyric_melisma() throws {
        // FF 05 00 — a zero-length Lyric/Display meta-event denotes a
        // melisma (RP-017 §7) and must parse as an (empty) lyric, not a
        // .unknown fallback.
        let content: [UInt8] = [0x00, 0xff, 0x05, 0x00, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        if case let .meta(_, .lyric(text)) = sequence.tracks[0].events[0] {
            #expect(text.stringValue.isEmpty)
        } else {
            Issue.record("Expected empty lyric (melisma) meta-event")
        }
    }

    @Test
    func parse_endOfTrack_noDiagnostic() throws {
        // A well-formed FF 2F 00 (expected length 0) must parse as
        // .endOfTrack without emitting any length diagnostic.
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks[0].events[0].isEndOfTrack == true)
        #expect(diagnostics.isEmpty)
    }

    @Test
    func parse_format0() throws {
        let data = makeFormat0Data()
        let parser = SMFParser()
        let (sequence, _) = try parser.parse(data)

        #expect(sequence.format == .format0)
        #expect(sequence.tracks.count == 1)
    }

    @Test
    func parse_format0Example_roundTrip() throws {
        let data = try loadFixture("format0_example", extension: "mid")
        let (sequence, _) = try SMFParser().parse(data)
        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == data)
    }

    @Test
    func parse_format0Example_structure() throws {
        let data = try loadFixture("format0_example", extension: "mid")
        let (sequence, _) = try SMFParser().parse(data)

        #expect(sequence.format == .format0)
        #expect(sequence.division.bytesValue == [0x00, 0x60])
        #expect(sequence.tracks.count == 1)

        let events = sequence.tracks[0].events

        #expect(events.count == 14)

        if case let .meta(t, .timeSignature) = events[0] {
            #expect(t == .zero)
        } else {
            Issue.record("Expected timeSignature at events[0]")
        }

        if case let .meta(t, .tempo(bpm)) = events[1] {
            #expect(t == .zero)
            #expect(bpm.uintValue == 500_000)
        } else {
            Issue.record("Expected tempo at events[1]")
        }

        #expect(events.last?.isEndOfTrack == true)

        if case let .meta(t, .endOfTrack) = events[13] {
            #expect(t.uintValue == 384)
        } else {
            Issue.record("Expected endOfTrack at events[13]")
        }
    }

    @Test
    func parse_format0ManyTracks_leftDenormalized() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0002, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])
        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.format == .format0)
        #expect(sequence.tracks.count == 2)
    }

    @Test
    func parse_format1Example_roundTrip() throws {
        let data = try loadFixture("format1_example", extension: "mid")
        let (sequence, _) = try SMFParser().parse(data)
        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == data)
    }

    @Test
    func parse_format1Example_structure() throws {
        let data = try loadFixture("format1_example", extension: "mid")
        let (sequence, _) = try SMFParser().parse(data)

        #expect(sequence.format == .format1)
        #expect(sequence.division.bytesValue == [0x00, 0x60])
        #expect(sequence.tracks.count == 4)

        #expect(sequence.tracks[0].events.count == 3)   // time-sig, tempo, EOT
        #expect(sequence.tracks[1].events.count == 4)   // prog, note-on, note-off, EOT
        #expect(sequence.tracks[2].events.count == 4)   // prog, note-on, note-off, EOT
        #expect(sequence.tracks[3].events.count == 6)   // prog, 2×note-on, 2×note-off, EOT

        for track in sequence.tracks {
            #expect(track.events.last?.isEndOfTrack == true)
        }

        if case let .meta(t, .endOfTrack) = sequence.tracks[0].events[2] {
            #expect(t.uintValue == 384)
        } else {
            Issue.record("Expected endOfTrack at track0 events[2]")
        }
    }

    @Test
    func parse_format2_accepted() throws {
        var bytes = makeHeaderBytes(format: 0x0002, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.format == .format2)
        #expect(sequence.tracks.count == 1)
    }

    @Test
    func parse_highTrackCount() throws {
        var bytes: [UInt8] = []

        bytes += [0x4d, 0x54, 0x68, 0x64]
        bytes += [0x00, 0x00, 0x00, 0x06]
        bytes += [0x00, 0x01]
        bytes += [0x00, 0x02]   // ntrks declares 2
        bytes += [0x01, 0xe0]

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])  // only 1 track provided

        let parser = SMFParser()
        let (sequence, diagnostics) = try parser.parse(Data(bytes))

        #expect(sequence.tracks.count == 1)
        #expect(diagnostics.contains(.trackCountMismatch(declared: 2, actual: 1)))
    }

    @Test
    func parse_highTrackCount_notRejected() throws {
        var bytes: [UInt8] = []

        bytes += [0x4d, 0x54, 0x68, 0x64]
        bytes += [0x00, 0x00, 0x00, 0x06]
        bytes += [0x00, 0x01]
        bytes += [0x80, 0x00]
        bytes += [0x01, 0xe0]

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

        // Track count 0x8000 is accepted; with no MTrk chunks following, the
        // parser hands back an empty-tracks sequence and reports the mismatch.
        // Rejecting a zero-track sequence is SMFValidator's responsibility.
        #expect(sequence.tracks.isEmpty)
        #expect(diagnostics.contains(.trackCountMismatch(declared: 0x8000, actual: 0)))
    }

    @Test
    func parse_invalid_emptyData() {
        let parser = SMFParser()

        #expect(throws: (any Error).self) {
            try parser.parse(Data())
        }
    }

    @Test
    func parse_invalid_missingHeader() {
        let data = Data([0x4d, 0x54, 0x72, 0x6b, 0x00, 0x00, 0x00, 0x04, 0x00, 0xff, 0x2f, 0x00])
        let parser = SMFParser()

        #expect(throws: (any Error).self) {
            try parser.parse(data)
        }
    }

    @Test
    func parse_invalidChannelMessage_throws() {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        // Note-on (0x90) with an out-of-range velocity data byte (0x80);
        // the reader accepts any raw byte structurally, but constructing
        // the message from it fails.
        bytes += makeTrackBytes([0x00, 0x90, 0x3c, 0x80])

        #expect(throws: SMFParser.Error.invalidChannelMessage(0x90, [0x3c, 0x80])) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_invalidChunkType_throws() {
        // Chunk id byte 0x80 is not ASCII, so the chunk type cannot be
        // decoded even before the header is located.
        let data = Data([0x80, 0x54, 0x68, 0x64])

        #expect(throws: SMFParser.Error.invalidChunkType("\u{80}Thd")) {
            try SMFParser().parse(data)
        }
    }

    @Test
    func parse_invalidDivision_throws() {
        // Division byte 0 (0xe0) has its high bit set (SMPTE format) but
        // does not match any valid SMPTE frame rate byte.
        var bytes: [UInt8] = []

        bytes += [0x4d, 0x54, 0x68, 0x64]
        bytes += [0x00, 0x00, 0x00, 0x06]
        bytes += [0x00, 0x00]
        bytes += [0x00, 0x01]
        bytes += [0xe0, 0x00]

        #expect(throws: SMFParser.Error.invalidDivision([0xe0, 0x00])) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_invalidDivision_zeroTicksPerFrame_throws() {
        // SMPTE division at 24 fps (0xe8) with zero ticks per frame.
        var bytes: [UInt8] = []

        bytes += [0x4d, 0x54, 0x68, 0x64]
        bytes += [0x00, 0x00, 0x00, 0x06]
        bytes += [0x00, 0x00]
        bytes += [0x00, 0x01]
        bytes += [0xe8, 0x00]

        #expect(throws: SMFParser.Error.invalidDivision([0xe8, 0x00])) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_invalidEventTime_throws() {
        // Nine events each advancing the cumulative tick count by the
        // maximum encodable delta-time (0x0fffffff) push the running total
        // past SMFEventTime's 0x7fffffff maximum.
        var content: [UInt8] = [0xff, 0xff, 0xff, 0x7f, 0x90, 0x3c, 0x64]

        for _ in 0..<7 {
            content += [0xff, 0xff, 0xff, 0x7f, 0x3c, 0x64]
        }

        content += [0x08]

        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        #expect(throws: SMFParser.Error.invalidEventTime(0x80000000)) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_invalidFormat_throws() {
        // Format value 3 is not a valid SMF format (only 0, 1, and 2 are
        // defined).
        var bytes: [UInt8] = []

        bytes += [0x4d, 0x54, 0x68, 0x64]
        bytes += [0x00, 0x00, 0x00, 0x06]
        bytes += [0x00, 0x03]
        bytes += [0x00, 0x01]
        bytes += [0x01, 0xe0]

        #expect(throws: SMFParser.Error.invalidFormat([0x00, 0x03])) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_keySignature_roundTrip() throws {
        // C major: FF 59 02 00 00
        let content: [UInt8] = [0x00, 0xff, 0x59, 0x02, 0x00, 0x00, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        if case let .meta(_, .keySignature(ks)) = sequence.tracks[0].events[0] {
            #expect(ks == .cMajor)
        } else {
            Issue.record("Expected keySignature event")
        }

        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == Data(bytes))
    }

    @Test
    func parse_missingEndOfTrack_succeeds() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0x90, 0x3c, 0x40])

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks[0].events.count == 1)
        #expect(sequence.tracks[0].events[0].isEndOfTrack == false)
    }

    @Test
    func parse_multiPacketSysEx_roundTrip() throws {
        // F0 packet without terminal F7, followed by F7 continuation
        let content: [UInt8] = [0x00,
                                0xf0,
                                0x02,
                                0x41,
                                0x10,
                                0x00,
                                0xf7,
                                0x02,
                                0x02,
                                0xf7,
                                0x00,
                                0xff,
                                0x2f,
                                0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks[0].events.count == 3)

        if case let .sysEx(_, .systemExclusive(data)) = sequence.tracks[0].events[0] {
            #expect(data == [0x41, 0x10])
        } else {
            Issue.record("Expected systemExclusive at events[0]")
        }

        if case let .sysEx(_, .escape(data)) = sequence.tracks[0].events[1] {
            #expect(data == [0x02, 0xf7])
        } else {
            Issue.record("Expected escape at events[1]")
        }

        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == Data(bytes))
    }

    @Test
    func parse_overLongMetaEvent_clamped() throws {
        // FF 51 04 07 A1 20 FF — a tempo meta-event declaring 4 data bytes
        // (one more than the 3 the type defines). RP-001 (p.7) requires it
        // be recognized as a tempo, ignoring the surplus byte.
        let content: [UInt8] = [0x00,
                                0xff,
                                0x51,
                                0x04,
                                0x07,
                                0xa1,
                                0x20,
                                0xff,
                                0x00,
                                0xff,
                                0x2f,
                                0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

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
    func parse_overLongVarlen_clamped() throws {
        // A 5-byte delta-time (FF FF FF FF 7F) encodes a value larger than
        // the 0x0fffffff maximum defined by RP-001 (p.2); it must be clamped
        // to that maximum, not overflow.
        let content: [UInt8] = [0xff,
                                0xff,
                                0xff,
                                0xff,
                                0x7f,
                                0x90,
                                0x3c,
                                0x40,
                                0x00,
                                0xff,
                                0x2f,
                                0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

        if case let .midi(t, _) = sequence.tracks[0].events[0] {
            #expect(t.uintValue == 0x0fffffff)
        } else {
            Issue.record("Expected MIDI event at events[0]")
        }

        #expect(diagnostics.contains(.variableLengthQuantityClamped))
    }

    @Test
    func parse_postEOTPadding_succeeds() throws {
        let content: [UInt8] = [0x00, 0xff, 0x2f, 0x00, 0x00, 0x00, 0x00]
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks[0].events.count == 1)
        #expect(sequence.tracks[0].events[0].isEndOfTrack == true)
    }

    @Test
    func parse_roundTrip() throws {
        let data = makeFormat0Data()
        let parser = SMFParser()
        let (sequence, _) = try parser.parse(data)
        let formatted = try SMFFormatter().format(makeValidatedSequence(sequence))
        let (reparsed, _) = try parser.parse(formatted)

        #expect(reparsed.format == .format0)
        #expect(reparsed.tracks.count == 1)
    }

    @Test
    func parse_runningStatusWithMultiByteDelta_roundTrip() throws {
        // delta=200 in VLQ: 200 = 128+72 → 0x81 0x48
        let content: [UInt8] = [0x00,
                                0x90,
                                0x3c,
                                0x64,
                                0x81,
                                0x48,
                                0x3e,
                                0x64,
                                0x00,
                                0xff,
                                0x2f,
                                0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks[0].events.count == 3)

        if case let .midi(t, _) = sequence.tracks[0].events[1] {
            #expect(t.uintValue == 200)
        } else {
            Issue.record("Expected MIDI event at events[1]")
        }

        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == Data(bytes))
    }

    @Test
    func parse_smpteOffset_roundTrip() throws {
        // FF 54 05: fps24 (bits 00), hour=1 → byte0 = 0x01; min=sec=frame=frac=0
        let content: [UInt8] = [0x00,
                                0xff,
                                0x54,
                                0x05,
                                0x01,
                                0x00,
                                0x00,
                                0x00,
                                0x00,
                                0x00,
                                0xff,
                                0x2f,
                                0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        if case let .meta(_, .smpteOffset(offset)) = sequence.tracks[0].events[0] {
            #expect(offset.frameRate == .fps24)
            #expect(offset.hour == 1)
            #expect(offset.minute == 0)
            #expect(offset.second == 0)
            #expect(offset.frame == 0)
            #expect(offset.fraction == 0)
        } else {
            Issue.record("Expected smpteOffset meta event")
        }

        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == Data(bytes))
    }

    @Test
    func parse_smpteTimeDivision_roundTrip() throws {
        // SMPTE fps25, 40 ticks/frame → division bytes [E7, 28]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0xe728)

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        guard case let .timeCode(tc) = sequence.division else {
            Issue.record("Expected timeCode division")
            return
        }

        #expect(tc.frameRate == .fps25)
        #expect(tc.ticksPerFrame == 40)

        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == Data(bytes))
    }

    @Test
    func parse_strayRealTimeBytes_skipped() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xf8, 0x90, 0x3c, 0x40, 0x00, 0xff, 0x2f, 0x00])

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks[0].events.count == 2)
        #expect(diagnostics.contains(.strayRealTimeByteSkipped))
    }

    @Test
    func parse_sysExEscapeF7_roundTrip() throws {
        let content: [UInt8] = [0x00, 0xf7, 0x02, 0x42, 0xf7, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        if case let .sysEx(_, .escape(data)) = sequence.tracks[0].events[0] {
            #expect(data == [0x42, 0xf7])
        } else {
            Issue.record("Expected escape sysex event")
        }

        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == Data(bytes))
    }

    @Test
    func parse_sysExF0_roundTrip() throws {
        let content: [UInt8] = [0x00, 0xf0, 0x03, 0x41, 0x10, 0xf7, 0x00, 0xff, 0x2f, 0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        if case let .sysEx(_, .systemExclusive(data)) = sequence.tracks[0].events[0] {
            #expect(data == [0x41, 0x10, 0xf7])
        } else {
            Issue.record("Expected systemExclusive event")
        }

        let reformatted = try SMFFormatter().format(makeValidatedSequence(sequence))

        #expect(reformatted == Data(bytes))
    }

    @Test
    func parse_tooManyHeaderChunks_throws() {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += [0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x00]

        #expect(throws: SMFParser.Error.tooManyHeaderChunks) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_truncatedTrack_emitsDiagnostic() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += [0x4d, 0x54, 0x72, 0x6b, 0x00, 0x00, 0x00, 0x0a]
        bytes += [0x00, 0xff, 0x2f, 0x00]

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks.count == 1)
        #expect(diagnostics.contains {
            if case .chunkLengthClamped = $0 {
                return true
            }

            return false
        })
    }

    @Test
    func parse_underLongMetaEvent_diagnostic() throws {
        // FF 51 02 07 A1 — a tempo meta-event declaring only 2 of the 3
        // data bytes the type defines. The missing byte cannot be
        // recovered, so the event degrades to `.unknown`, but the parser
        // reports the malformed length.
        let content: [UInt8] = [0x00,
                                0xff,
                                0x51,
                                0x02,
                                0x07,
                                0xa1,
                                0x00,
                                0xff,
                                0x2f,
                                0x00]
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes(content)

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

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
    func parse_unexpectedDataByte_throws() {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        // A data byte (0x3c) appears where a status byte is expected, with
        // no running status set yet.
        bytes += makeTrackBytes([0x00, 0x3c])

        #expect(throws: SMFParser.Error.unexpectedDataByte(0x3c)) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_unknownEventStatus_throws() {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        // 0xf1 is a MIDI status byte but is neither a MIDI event, meta, nor
        // sysex event status byte.
        bytes += makeTrackBytes([0x00, 0xf1])

        #expect(throws: SMFParser.Error.unknownEventStatus(0xf1)) {
            try SMFParser().parse(Data(bytes))
        }
    }

    @Test
    func parse_unknownMetaEvent() throws {
        var bytes: [UInt8] = []

        bytes += [0x4d, 0x54, 0x68, 0x64]
        bytes += [0x00, 0x00, 0x00, 0x06]
        bytes += [0x00, 0x00]
        bytes += [0x00, 0x01]
        bytes += [0x01, 0xe0]

        bytes += [0x4d, 0x54, 0x72, 0x6b]
        bytes += [0x00, 0x00, 0x00, 0x0a]
        bytes += [0x00, 0xff, 0x42, 0x02, 0xde, 0xad]
        bytes += [0x00, 0xff, 0x2f, 0x00]

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks.count == 1)
        #expect(sequence.tracks[0].events.count == 2)

        if case let .meta(_, .unknown(typeByte, data)) = sequence.tracks[0].events[0] {
            #expect(typeByte == 0x42)
            #expect(data == [0xde, 0xad])
        } else {
            Issue.record("Expected unknown meta-event")
        }
    }

    @Test
    func parse_wrongNtrksHigh_succeeds() throws {
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0002, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks.count == 1)
        #expect(diagnostics.contains(.trackCountMismatch(declared: 2, actual: 1)))
    }

    @Test
    func parse_wrongNtrksLow_succeeds() throws {
        var bytes = makeHeaderBytes(format: 0x0001, ntrks: 0x0001, division: 0x01e0)

        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])
        bytes += makeTrackBytes([0x00, 0xff, 0x2f, 0x00])

        let (sequence, diagnostics) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks.count == 2)
        #expect(diagnostics.contains(.trackCountMismatch(declared: 1, actual: 2)))
    }

    @Test
    func parse_zeroLengthMTrk_succeeds() throws {
        var bytes = makeHeaderBytes(format: 0x0000, ntrks: 0x0001, division: 0x01e0)

        bytes += [0x4d, 0x54, 0x72, 0x6b, 0x00, 0x00, 0x00, 0x00]

        let (sequence, _) = try SMFParser().parse(Data(bytes))

        #expect(sequence.tracks.count == 1)
        #expect(sequence.tracks[0].events.isEmpty)
    }
}
