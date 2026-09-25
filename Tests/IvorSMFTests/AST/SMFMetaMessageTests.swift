// © 2025–2026 John Gary Pusey (see LICENSE.md)

import IvorMIDI
@testable import IvorSMF
import IvorSMPTE
import Testing

struct SMFMetaMessageTests {
}

// MARK: -

extension SMFMetaMessageTests {
    @Test
    func dataBytes_endOfTrack() {
        #expect(SMFMetaMessage.endOfTrack.dataBytes?.isEmpty == true)
    }

    @Test
    func dataBytes_keySignature() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x59, dataBytes: [0x00, 0x00])

        #expect(msg?.dataBytes == [0x00, 0x00])
    }

    @Test
    func dataBytes_midiChannelPrefix() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x20, dataBytes: [0x00])

        #expect(msg?.dataBytes == [0x00])
    }

    @Test
    func dataBytes_midiPort() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x21, dataBytes: [0x00])

        #expect(msg?.dataBytes == [0x00])
    }

    @Test
    func dataBytes_sequenceNumber() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x00, dataBytes: [0x00, 0x01])

        #expect(msg?.dataBytes == [0x00, 0x01])
    }

    @Test
    func dataBytes_sequencerSpecific() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x7f, dataBytes: [0x01, 0x02, 0x03])

        #expect(msg?.dataBytes == [0x01, 0x02, 0x03])
    }

    @Test
    func dataBytes_smpteOffset() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x54,
                                 dataBytes: [0x01, 0x02, 0x03, 0x04, 0x05])

        #expect(msg?.dataBytes == [0x01, 0x02, 0x03, 0x04, 0x05])
    }

    @Test
    func dataBytes_tempo() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x51, dataBytes: [0x07, 0xa1, 0x20])

        #expect(msg?.dataBytes == [0x07, 0xa1, 0x20])
    }

    @Test
    func dataBytes_text() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x01, dataBytes: Array("hi".utf8))

        #expect(msg?.dataBytes == Array("hi".utf8))
    }

    @Test
    func dataBytes_timeSignature() {
        let msg = SMFMetaMessage(statusByte: 0xff, typeByte: 0x58, dataBytes: [0x04, 0x02, 0x18, 0x08])

        #expect(msg?.dataBytes == [0x04, 0x02, 0x18, 0x08])
    }

    @Test
    func dataBytes_unknown() {
        let msg = SMFMetaMessage.unknown(0x42, [0x01, 0x02])

        #expect(msg.dataBytes == [0x01, 0x02])
    }

    @Test
    func equality_endOfTrack() {
        #expect(SMFMetaMessage.endOfTrack == .endOfTrack)
    }

    @Test
    func equality_unknown() {
        #expect(SMFMetaMessage.unknown(0x42, [0x01, 0x02]) == .unknown(0x42, [0x01, 0x02]))
    }

    @Test
    func fixedDataByteCount() {
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x00) == 2)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x20) == 1)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x21) == 1)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x2f) == 0)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x51) == 3)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x54) == 5)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x58) == 4)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x59) == 2)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x01) == nil)
        #expect(SMFMetaMessage.fixedDataByteCount(forTypeByte: 0x7f) == nil)
    }

    @Test
    func hashable() {
        let set: Set<SMFMetaMessage> = [.endOfTrack, .endOfTrack, .unknown(0x42, [0x01])]

        #expect(set.count == 2)
    }

    @Test
    func inequality_differentCases() {
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping

        #expect(SMFMetaMessage.endOfTrack != .tempo(tempo))
    }

    @Test
    func inequality_differentData() {
        #expect(SMFMetaMessage.unknown(0x42, [0x01]) != .unknown(0x42, [0x02]))
    }

    @Test
    func inequality_differentType() {
        #expect(SMFMetaMessage.unknown(0x42, []) != .unknown(0x43, []))
    }

    @Test
    func init_copyright() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x02,
                                 dataBytes: Array("(c)".utf8))

        #expect(msg != nil)

        if case let .copyright(text) = msg {
            #expect(text.stringValue == "(c)")
        } else {
            Issue.record("Expected copyright")
        }
    }

    @Test
    func init_cuePoint() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x07,
                                 dataBytes: Array("cue".utf8))

        #expect(msg != nil)

        if case .cuePoint = msg {
        } else {
            Issue.record("Expected cuePoint")
        }
    }

    @Test
    func init_deviceName() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x09,
                                 dataBytes: Array("dev".utf8))

        #expect(msg != nil)

        if case .deviceName = msg {
        } else {
            Issue.record("Expected deviceName")
        }
    }

    @Test
    func init_endOfTrack() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x2f,
                                 dataBytes: [])

        #expect(msg != nil)

        if case .endOfTrack = msg {
        } else {
            Issue.record("Expected endOfTrack")
        }
    }

    @Test
    func init_endOfTrack_nonEmptyData() {
        #expect(SMFMetaMessage(statusByte: 0xff,
                               typeByte: 0x2f,
                               dataBytes: [0x00]) == nil)
    }

    @Test
    func init_instrumentName() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x04,
                                 dataBytes: Array("Piano".utf8))

        #expect(msg != nil)

        if case .instrumentName = msg {
        } else {
            Issue.record("Expected instrumentName")
        }
    }

    @Test
    func init_invalid_statusByte() {
        #expect(SMFMetaMessage(statusByte: 0xfe,
                               typeByte: 0x2f,
                               dataBytes: []) == nil)
    }

    @Test
    func init_invalid_typeByte() {
        #expect(SMFMetaMessage(statusByte: 0xff,
                               typeByte: 0x10,
                               dataBytes: []) == nil)
    }

    @Test
    func init_invalid_wrongDataByteCount() {
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x00, dataBytes: [0x00]) == nil)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x20, dataBytes: []) == nil)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x21, dataBytes: []) == nil)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x51, dataBytes: [0x00]) == nil)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x54, dataBytes: [0x00]) == nil)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x58, dataBytes: [0x00]) == nil)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x59, dataBytes: [0x00]) == nil)
    }

    @Test
    func init_keySignature() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x59,
                                 dataBytes: [0x00, 0x00])

        #expect(msg != nil)

        if case let .keySignature(keySig) = msg {
            #expect(keySig == .cMajor)
        } else {
            Issue.record("Expected keySignature")
        }
    }

    @Test
    func init_lyric() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x05,
                                 dataBytes: Array("la".utf8))

        #expect(msg != nil)

        if case .lyric = msg {
        } else {
            Issue.record("Expected lyric")
        }
    }

    @Test
    func init_marker() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x06,
                                 dataBytes: Array("A".utf8))

        #expect(msg != nil)

        if case .marker = msg {
        } else {
            Issue.record("Expected marker")
        }
    }

    @Test
    func init_midiChannelPrefix() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x20,
                                 dataBytes: [0x00])

        #expect(msg != nil)

        if case let .midiChannelPrefix(channel) = msg {
            #expect(channel.uintValue == 1)
        } else {
            Issue.record("Expected midiChannelPrefix")
        }
    }

    @Test
    func init_midiPort() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x21,
                                 dataBytes: [0x00])

        #expect(msg != nil)

        if case let .midiPort(port) = msg {
            #expect(port.uintValue == 0)
        } else {
            Issue.record("Expected midiPort")
        }
    }

    @Test
    func init_programName() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x08,
                                 dataBytes: Array("pgm".utf8))

        #expect(msg != nil)

        if case .programName = msg {
        } else {
            Issue.record("Expected programName")
        }
    }

    @Test
    func init_reservedTextA() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x0a,
                                 dataBytes: Array("A".utf8))

        #expect(msg != nil)

        if case .reservedTextA = msg {
        } else {
            Issue.record("Expected reservedTextA")
        }
    }

    @Test
    func init_reservedTextB() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x0b,
                                 dataBytes: Array("B".utf8))

        #expect(msg != nil)

        if case .reservedTextB = msg {
        } else {
            Issue.record("Expected reservedTextB")
        }
    }

    @Test
    func init_reservedTextC() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x0c,
                                 dataBytes: Array("C".utf8))

        #expect(msg != nil)

        if case .reservedTextC = msg {
        } else {
            Issue.record("Expected reservedTextC")
        }
    }

    @Test
    func init_reservedTextD() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x0d,
                                 dataBytes: Array("D".utf8))

        #expect(msg != nil)

        if case .reservedTextD = msg {
        } else {
            Issue.record("Expected reservedTextD")
        }
    }

    @Test
    func init_reservedTextE() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x0e,
                                 dataBytes: Array("E".utf8))

        #expect(msg != nil)

        if case .reservedTextE = msg {
        } else {
            Issue.record("Expected reservedTextE")
        }
    }

    @Test
    func init_reservedTextF() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x0f,
                                 dataBytes: Array("F".utf8))

        #expect(msg != nil)

        if case .reservedTextF = msg {
        } else {
            Issue.record("Expected reservedTextF")
        }
    }

    @Test
    func init_sequenceNumber() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x00,
                                 dataBytes: [0x00, 0x01])

        #expect(msg != nil)

        if case let .sequenceNumber(seqNum) = msg {
            #expect(seqNum.uintValue == 1)
        } else {
            Issue.record("Expected sequenceNumber")
        }
    }

    @Test
    func init_sequencerSpecific() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x7f,
                                 dataBytes: [0x01, 0x02, 0x03])

        #expect(msg != nil)

        if case let .sequencerSpecific(data) = msg {
            #expect(data == [0x01, 0x02, 0x03])
        } else {
            Issue.record("Expected sequencerSpecific")
        }
    }

    @Test
    func init_sequencerSpecific_empty() {
        #expect(SMFMetaMessage(statusByte: 0xff,
                               typeByte: 0x7f,
                               dataBytes: []) == nil)
    }

    @Test
    func init_sequenceTrackName() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x03,
                                 dataBytes: Array("Track 1".utf8))

        #expect(msg != nil)

        if case let .sequenceTrackName(text) = msg {
            #expect(text.stringValue == "Track 1")
        } else {
            Issue.record("Expected sequenceTrackName")
        }
    }

    @Test
    func init_smpteOffset() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x54,
                                 dataBytes: [0x01, 0x02, 0x03, 0x04, 0x05])

        #expect(msg != nil)

        if case let .smpteOffset(time) = msg {
            #expect(time.hour == 1)
            #expect(time.minute == 2)
        } else {
            Issue.record("Expected smpteOffset")
        }
    }

    @Test
    func init_tempo() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x51,
                                 dataBytes: [0x07, 0xa1, 0x20])

        #expect(msg != nil)

        if case let .tempo(tempo) = msg {
            #expect(tempo.uintValue == 500_000)
        } else {
            Issue.record("Expected tempo")
        }
    }

    @Test
    func init_text() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x01,
                                 dataBytes: Array("hello".utf8))

        #expect(msg != nil)

        if case let .text(text) = msg {
            #expect(text.stringValue == "hello")
        } else {
            Issue.record("Expected text")
        }
    }

    @Test
    func init_timeSignature() {
        let msg = SMFMetaMessage(statusByte: 0xff,
                                 typeByte: 0x58,
                                 dataBytes: [0x04, 0x02, 0x18, 0x08])

        #expect(msg != nil)

        if case let .timeSignature(timeSig) = msg {
            #expect(timeSig.numerator == 4)
            #expect(timeSig.denominator == 2)
        } else {
            Issue.record("Expected timeSignature")
        }
    }

    @Test
    func statusByte() {
        #expect(SMFMetaMessage.endOfTrack.statusByte == 0xff)
    }

    @Test
    func typeByte() {
        #expect(SMFMetaMessage.endOfTrack.typeByte == 0x2f)

        let text = SMFMetaMessage(statusByte: 0xff,
                                  typeByte: 0x01,
                                  dataBytes: Array("hi".utf8))

        #expect(text?.typeByte == 0x01)
    }

    @Test
    func typeByte_allCases() {
        let text = SMFText(stringValue: "x")!                       // swiftlint:disable:this force_unwrapping
        let seqNum = SMFData2Value(uintValue: 0)!                    // swiftlint:disable:this force_unwrapping
        let channel = MIDIChannel(uintValue: 1)!                     // swiftlint:disable:this force_unwrapping
        let port = MIDIData1Value(uintValue: 0)!                     // swiftlint:disable:this force_unwrapping
        let tempo = SMFTempo(uintValue: 500_000)!                    // swiftlint:disable:this force_unwrapping
        let offset = SMPTETime(frameRate: .fps24,
                               hour: 0,
                               minute: 0,
                               second: 0,
                               frame: 0,
                               fraction: 0)!                // swiftlint:disable:this force_unwrapping
        let timeSig = SMFTimeSignature(numerator: 4,
                                       denominator: 2,
                                       clockRate: 24,
                                       beatRate: 8)!   // swiftlint:disable:this force_unwrapping

        #expect(SMFMetaMessage.copyright(text).typeByte == 0x02)
        #expect(SMFMetaMessage.cuePoint(text).typeByte == 0x07)
        #expect(SMFMetaMessage.deviceName(text).typeByte == 0x09)
        #expect(SMFMetaMessage.instrumentName(text).typeByte == 0x04)
        #expect(SMFMetaMessage.keySignature(.cMajor).typeByte == 0x59)
        #expect(SMFMetaMessage.lyric(text).typeByte == 0x05)
        #expect(SMFMetaMessage.marker(text).typeByte == 0x06)
        #expect(SMFMetaMessage.midiChannelPrefix(channel).typeByte == 0x20)
        #expect(SMFMetaMessage.midiPort(port).typeByte == 0x21)
        #expect(SMFMetaMessage.programName(text).typeByte == 0x08)
        #expect(SMFMetaMessage.sequenceNumber(seqNum).typeByte == 0x00)
        #expect(SMFMetaMessage.sequencerSpecific([0x01]).typeByte == 0x7f)
        #expect(SMFMetaMessage.sequenceTrackName(text).typeByte == 0x03)
        #expect(SMFMetaMessage.smpteOffset(offset).typeByte == 0x54)
        #expect(SMFMetaMessage.tempo(tempo).typeByte == 0x51)
        #expect(SMFMetaMessage.timeSignature(timeSig).typeByte == 0x58)
    }

    @Test
    func typeByte_reservedText() {
        let bytes = Array("x".utf8)

        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x0a, dataBytes: bytes)?.typeByte == 0x0a)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x0b, dataBytes: bytes)?.typeByte == 0x0b)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x0c, dataBytes: bytes)?.typeByte == 0x0c)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x0d, dataBytes: bytes)?.typeByte == 0x0d)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x0e, dataBytes: bytes)?.typeByte == 0x0e)
        #expect(SMFMetaMessage(statusByte: 0xff, typeByte: 0x0f, dataBytes: bytes)?.typeByte == 0x0f)
    }

    @Test
    func typeByte_unknown() {
        #expect(SMFMetaMessage.unknown(0x42, []).typeByte == 0x42)
    }
}
