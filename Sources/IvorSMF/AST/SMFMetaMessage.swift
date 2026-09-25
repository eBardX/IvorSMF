// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI
public import IvorSMPTE

/// An SMF meta-event message.
public enum SMFMetaMessage {

    /// A copyright notice.
    case copyright(SMFText)

    /// A cue point.
    case cuePoint(SMFText)

    /// A device name.
    case deviceName(SMFText)

    /// An end of track marker.
    case endOfTrack

    /// An instrument name.
    case instrumentName(SMFText)

    /// A key signature.
    case keySignature(SMFKeySignature)

    /// A lyric.
    case lyric(SMFText)

    /// A marker.
    case marker(SMFText)

    /// A MIDI channel prefix.
    case midiChannelPrefix(MIDIChannel)

    /// A MIDI port assignment.
    case midiPort(MIDIData1Value)

    /// A program name.
    case programName(SMFText)

    /// A reserved text event (type 0x0A).
    case reservedTextA(SMFText)

    /// A reserved text event (type 0x0B).
    case reservedTextB(SMFText)

    /// A reserved text event (type 0x0C).
    case reservedTextC(SMFText)

    /// A reserved text event (type 0x0D).
    case reservedTextD(SMFText)

    /// A reserved text event (type 0x0E).
    case reservedTextE(SMFText)

    /// A reserved text event (type 0x0F).
    case reservedTextF(SMFText)

    /// A sequence number.
    case sequenceNumber(SMFData2Value)

    /// Sequencer-specific data.
    case sequencerSpecific([UInt8])

    /// A sequence or track name.
    case sequenceTrackName(SMFText)

    /// A SMPTE offset.
    case smpteOffset(SMPTETime)

    /// A tempo change, in microseconds per quarter note.
    case tempo(SMFTempo)

    /// A text event.
    case text(SMFText)

    /// A time signature.
    case timeSignature(SMFTimeSignature)

    /// An unrecognized meta-event, preserving its type byte and raw data bytes.
    case unknown(UInt8, [UInt8])

    // MARK: Internal Initializers

    internal init?(statusByte: UInt8,
                   typeByte: UInt8,
                   dataBytes: [UInt8]) {
        guard statusByte == 0xff
        else { return nil }

        switch typeByte {
        case 0x00:
            guard let seqNum = SMFData2Value(bytesValue: dataBytes)
            else { return nil }

            self = .sequenceNumber(seqNum)

        case 0x01...0x0f:
            guard let message = Self._makeTextMessage(typeByte,
                                                      dataBytes)
            else { return nil }

            self = message

        case 0x20:
            guard let channel = MIDIChannel(bytesValue: dataBytes)
            else { return nil }

            self = .midiChannelPrefix(channel)

        case 0x21:
            guard let port = MIDIData1Value(bytesValue: dataBytes)
            else { return nil }

            self = .midiPort(port)

        case 0x2f where dataBytes.isEmpty:
            self = .endOfTrack

        case 0x51:
            guard let tempo = SMFTempo(bytesValue: dataBytes)
            else { return nil }

            self = .tempo(tempo)

        case 0x54:
            guard let offset = SMPTETime(bytesValue: dataBytes)
            else { return nil }

            self = .smpteOffset(offset)

        case 0x58:
            guard let timeSig = SMFTimeSignature(bytesValue: dataBytes)
            else { return nil }

            self = .timeSignature(timeSig)

        case 0x59:
            guard let keySig = SMFKeySignature(bytesValue: dataBytes)
            else { return nil }

            self = .keySignature(keySig)

        case 0x7f where !dataBytes.isEmpty:
            self = .sequencerSpecific(dataBytes)

        default:
            return nil
        }
    }
}

// MARK: -

extension SMFMetaMessage {

    // MARK: Internal Type Methods

    // RP-001 (p.7) requires that a recognized meta-event be honored even
    // when its declared length exceeds what the type defines, ignoring the
    // surplus bytes; this lets the parser truncate an over-long payload
    // rather than demoting the event to `.unknown`. Returns nil for
    // variable-length (text events 0x01-0x0f, sequencer-specific 0x7f) or
    // unrecognized types.
    internal static func fixedDataByteCount(forTypeByte typeByte: UInt8) -> Int? {
        switch typeByte {
        case 0x00:  // sequence number
            2

        case 0x20:  // MIDI channel prefix
            1

        case 0x21:  // MIDI port
            1

        case 0x2f:  // end of track
            0

        case 0x51:  // tempo
            3

        case 0x54:  // SMPTE offset
            5

        case 0x58:  // time signature
            4

        case 0x59:  // key signature
            2

        default:
            nil
        }
    }

    // MARK: Internal Instance Properties

    internal var dataBytes: [UInt8]? {
        switch self {
        case let .copyright(text),
             let .cuePoint(text),
             let .deviceName(text),
             let .instrumentName(text),
             let .lyric(text),
             let .marker(text),
             let .programName(text),
             let .reservedTextA(text),
             let .reservedTextB(text),
             let .reservedTextC(text),
             let .reservedTextD(text),
             let .reservedTextE(text),
             let .reservedTextF(text),
             let .sequenceTrackName(text),
             let .text(text):
            text.bytesValue

        case .endOfTrack:
            []

        case let .keySignature(keySig):
            keySig.bytesValue

        case let .midiChannelPrefix(channel):
            channel.bytesValue

        case let .midiPort(port):
            port.bytesValue

        case let .sequenceNumber(seqNum):
            seqNum.bytesValue

        case let .sequencerSpecific(dataBytes):
            dataBytes

        case let .smpteOffset(offset):
            offset.bytesValue

        case let .tempo(tempo):
            tempo.bytesValue

        case let .timeSignature(timeSig):
            timeSig.bytesValue

        case let .unknown(_, rawBytes):
            rawBytes
        }
    }

    internal var statusByte: UInt8? {
        0xff
    }

    internal var typeByte: UInt8? {
        switch self {
        case .copyright:
            0x02

        case .cuePoint:
            0x07

        case .deviceName:
            0x09

        case .endOfTrack:
            0x2f

        case .instrumentName:
            0x04

        case .keySignature:
            0x59

        case .lyric:
            0x05

        case .marker:
            0x06

        case .midiChannelPrefix:
            0x20

        case .midiPort:
            0x21

        case .programName:
            0x08

        case .reservedTextA:
            0x0a

        case .reservedTextB:
            0x0b

        case .reservedTextC:
            0x0c

        case .reservedTextD:
            0x0d

        case .reservedTextE:
            0x0e

        case .reservedTextF:
            0x0f

        case .sequenceNumber:
            0x00

        case .sequencerSpecific:
            0x7f

        case .sequenceTrackName:
            0x03

        case .smpteOffset:
            0x54

        case .tempo:
            0x51

        case .text:
            0x01

        case .timeSignature:
            0x58

        case let .unknown(typeByteValue, _):
            typeByteValue
        }
    }

    // MARK: Private Type Methods

    private static func _makeTextMessage(_ typeByte: UInt8,
                                         _ dataBytes: [UInt8]) -> Self? {
        guard let text = SMFText(bytesValue: dataBytes)
        else { return nil }

        switch typeByte {
        case 0x01:
            return .text(text)

        case 0x02:
            return .copyright(text)

        case 0x03:
            return .sequenceTrackName(text)

        case 0x04:
            return .instrumentName(text)

        case 0x05:
            return .lyric(text)

        case 0x06:
            return .marker(text)

        case 0x07:
            return .cuePoint(text)

        case 0x08:
            return .programName(text)

        case 0x09:
            return .deviceName(text)

        case 0x0a:
            return .reservedTextA(text)

        case 0x0b:
            return .reservedTextB(text)

        case 0x0c:
            return .reservedTextC(text)

        case 0x0d:
            return .reservedTextD(text)

        case 0x0e:
            return .reservedTextE(text)

        case 0x0f:
            return .reservedTextF(text)

        default:
            return nil
        }
    }
}

// MARK: - Equatable

extension SMFMetaMessage: Equatable {
}

// MARK: - Hashable

extension SMFMetaMessage: Hashable {
}

// MARK: - Sendable

extension SMFMetaMessage: Sendable {
}
