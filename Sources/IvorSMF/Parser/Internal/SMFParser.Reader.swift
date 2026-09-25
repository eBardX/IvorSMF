// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import Foundation
internal import IvorMIDI

extension SMFParser {

    // MARK: Internal Nested Types

    internal struct Reader {

        // MARK: Internal Initializers

        internal init(data: Data) {
            self.chunkBytesLeft = 0
            self.chunkMode = false
            self.currentIndex = 0
            self.currentTime = 0
            self.data = data
            self.diagnostics = []
            self.runningStatus = 0
        }

        // MARK: Private Instance Properties

        private let data: Data

        private var chunkBytesLeft: UInt
        private var chunkMode: Bool
        private var currentIndex: Int
        private var currentTime: UInt
        private var diagnostics: [SMFParser.Diagnostic]
        private var runningStatus: UInt8
    }
}

// MARK: -

extension SMFParser.Reader {

    // MARK: Internal Instance Methods

    internal mutating func readSequence() throws(SMFParser.Error) -> (SMFSequence, [SMFParser.Diagnostic]) {
        guard let chunkType = try _readChunk(),
              chunkType == .header
        else { throw SMFParser.Error.missingHeaderChunk }

        let (format, ntrks, division) = try _readHeader()

        var tracks: [SMFTrack] = []

        while let chunkType = try _readChunk() {
            switch chunkType {
            case .header:
                throw SMFParser.Error.tooManyHeaderChunks

            case .track:
                try tracks.append(_readTrack())

            default:
                break   // ignore unknown chunks
            }

            _skipExtraChunkData()
        }

        let actual = UInt(tracks.count)

        if actual != ntrks {
            diagnostics.append(.trackCountMismatch(declared: ntrks,
                                                   actual: actual))
        }

        return (SMFSequence(format: format,
                            division: division,
                            tracks: tracks), diagnostics)
    }

    // MARK: Private Type Properties

    // The maximum value encodable as an SMF variable-length quantity
    // (RP-001 p.2).
    private static let maxVarlen: UInt = 0x0fffffff

    // MARK: Private Instance Methods

    private mutating func _readByte() throws(SMFParser.Error) -> UInt8 {
        guard currentIndex < data.count,
              !chunkMode || chunkBytesLeft > 0
        else { throw SMFParser.Error.dataExhaustedPrematurely }

        let byte = data[currentIndex]

        currentIndex += 1

        if chunkMode {
            chunkBytesLeft -= 1
        }

        return byte
    }

    private mutating func _readBytes(_ count: UInt) throws(SMFParser.Error) -> [UInt8] {
        var dataBytes: [UInt8] = []

        for _ in 0..<count {
            try dataBytes.append(_readByte())
        }

        return dataBytes
    }

    private mutating func _readChunk() throws(SMFParser.Error) -> SMFChunkType? {
        _skipExtraChunkData()

        guard currentIndex < data.count
        else { return nil }

        chunkMode = false

        let chunkType = try _readChunkType()

        chunkBytesLeft = try _readChunkLength()

        let available = UInt(data.count - currentIndex)

        if chunkBytesLeft > available {
            diagnostics.append(.chunkLengthClamped(declared: chunkBytesLeft,
                                                   available: available))

            chunkBytesLeft = available
        }

        currentTime = 0
        runningStatus = 0

        return chunkType
    }

    private mutating func _readChunkLength() throws(SMFParser.Error) -> UInt {
        var chunkLength: UInt = 0

        for _ in 0..<4 {
            let byte = try _readByte()

            chunkLength = (chunkLength << 8) | UInt(byte)
        }

        return chunkLength
    }

    private mutating func _readChunkType() throws(SMFParser.Error) -> SMFChunkType {
        var rawChunkType = ""

        for _ in 0..<4 {
            let byte = try _readByte()

            rawChunkType.append(Character(Unicode.Scalar(byte)))
        }

        guard let chunkType = SMFChunkType(stringValue: rawChunkType)
        else { throw SMFParser.Error.invalidChunkType(rawChunkType) }

        return chunkType
    }

    private mutating func _readDivision() throws(SMFParser.Error) -> SMFDivision {
        let byte0Value = try _readByte()
        let byte1Value = try _readByte()

        guard let division = SMFDivision(bytesValue: [byte0Value, byte1Value])
        else { throw SMFParser.Error.invalidDivision([byte0Value, byte1Value]) }

        return division
    }

    private mutating func _readEvent() throws(SMFParser.Error) -> SMFEvent {
        let eventTime = try _readEventTime()

        let (statusByte, extraBytes) = try _readStatusByte()

        if statusByte.isMIDIEventStatusByte {
            return try _readMIDIEvent(at: eventTime,
                                      statusByte: statusByte,
                                      extraBytes: extraBytes)
        }

        if statusByte.isMetaEventStatusByte {
            return try _readMetaEvent(at: eventTime,
                                      statusByte: statusByte)
        }

        if statusByte.isSysExEventStatusByte {
            return try _readSysExEvent(at: eventTime,
                                       statusByte: statusByte)
        }

        throw SMFParser.Error.unknownEventStatus(statusByte)
    }

    private mutating func _readEventTime() throws(SMFParser.Error) -> SMFEventTime {
        currentTime += try _readVarlen()

        guard let eventTime = SMFEventTime(uintValue: currentTime)
        else { throw SMFParser.Error.invalidEventTime(currentTime) }

        return eventTime
    }

    private mutating func _readFormat() throws(SMFParser.Error) -> SMFFormat {
        let byte0Value = try _readByte()
        let byte1Value = try _readByte()

        guard let format = SMFFormat(bytesValue: [byte0Value, byte1Value])
        else { throw SMFParser.Error.invalidFormat([byte0Value, byte1Value]) }

        return format
    }

    private mutating func _readHeader() throws(SMFParser.Error) -> (SMFFormat, UInt, SMFDivision) {
        chunkMode = true

        let format = try _readFormat()
        let trackCount = try _readTrackCount()
        let division = try _readDivision()

        return (format, trackCount, division)
    }

    private mutating func _readMetaEvent(at eventTime: SMFEventTime,
                                         statusByte: UInt8) throws(SMFParser.Error) -> SMFEvent {
        let typeByte = try _readByte()
        let count = try _readVarlen()
        let dataBytes = try _readBytes(count)

        var payload = dataBytes

        // RP-001 (p.7): a recognized meta-event must be honored even when
        // its declared length is larger than the type defines; the surplus
        // bytes are ignored rather than causing the event to be treated as
        // unrecognized. A shorter-than-defined length cannot be recovered,
        // so the event degrades to `.unknown`, but the malformed length is
        // still reported.
        if let expected = SMFMetaMessage.fixedDataByteCount(forTypeByte: typeByte) {
            if dataBytes.count > expected {
                diagnostics.append(.metaEventLengthClamped(type: typeByte,
                                                           declared: UInt(dataBytes.count),
                                                           expected: UInt(expected)))

                payload = Array(dataBytes.prefix(expected))
            } else if dataBytes.count < expected {
                diagnostics.append(.metaEventLengthInvalid(type: typeByte,
                                                           declared: UInt(dataBytes.count),
                                                           expected: UInt(expected)))
            }
        }

        let message = SMFMetaMessage(statusByte: statusByte,
                                     typeByte: typeByte,
                                     dataBytes: payload) ?? .unknown(typeByte, dataBytes)

        runningStatus = 0

        return .meta(eventTime, message)
    }

    private mutating func _readMIDIEvent(at eventTime: SMFEventTime,
                                         statusByte: UInt8,
                                         extraBytes: [UInt8]) throws(SMFParser.Error) -> SMFEvent {
        guard let edbCount = MIDIChannelMessage.expectedDataByteCount(for: statusByte)
        else { throw SMFParser.Error.unknownChannelMessageStatus(statusByte) }

        var dataBytes = extraBytes

        while dataBytes.count < edbCount {
            try dataBytes.append(_readByte())
        }

        guard let message = MIDIChannelMessage(statusByte: statusByte,
                                               dataBytes: dataBytes)
        else { throw SMFParser.Error.invalidChannelMessage(statusByte, dataBytes) }

        runningStatus = statusByte

        return .midi(eventTime, message)
    }

    private mutating func _readStatusByte() throws(SMFParser.Error) -> (UInt8, [UInt8]) {
        var tmpByte = try _readByte()

        while tmpByte.isSystemRealTimeByte {
            diagnostics.append(.strayRealTimeByteSkipped)

            tmpByte = try _readByte()
        }

        if tmpByte.isMIDIStatusByte {
            return (tmpByte, [])
        }

        if runningStatus.isMIDIStatusByte {
            return (runningStatus, [tmpByte])
        }

        throw SMFParser.Error.unexpectedDataByte(tmpByte)
    }

    private mutating func _readSysExEvent(at eventTime: SMFEventTime,
                                          statusByte: UInt8) throws(SMFParser.Error) -> SMFEvent {
        let count = try _readVarlen()
        let dataBytes = try _readBytes(count)

        guard let message = SMFSysExMessage(statusByte: statusByte,
                                            dataBytes: dataBytes)
        else { throw SMFParser.Error.invalidSysExMessage(statusByte, dataBytes) }

        runningStatus = 0

        return .sysEx(eventTime, message)
    }

    private mutating func _readTrack() throws(SMFParser.Error) -> SMFTrack {
        chunkMode = true

        var events: [SMFEvent] = []

        while chunkBytesLeft > 0 {
            do {
                let event = try _readEvent()

                events.append(event)

                if event.isEndOfTrack {
                    break
                }
            } catch SMFParser.Error.dataExhaustedPrematurely {
                currentIndex = data.count
                chunkBytesLeft = 0
                break
            }
        }

        _skipExtraChunkData()

        return SMFTrack(events: events)
    }

    private mutating func _readTrackCount() throws(SMFParser.Error) -> UInt {
        let byte0Value = try _readByte()
        let byte1Value = try _readByte()

        return UInt(byte0Value) << 8 | UInt(byte1Value)
    }

    private mutating func _readVarlen() throws(SMFParser.Error) -> UInt {
        var varlen: UInt = 0
        var clamped = false

        while true {
            let byte = try _readByte()

            // RP-001 (p.2): a variable-length quantity must fit in 32 bits
            // (maximum 0x0fffffff). Stop accumulating once the value would
            // exceed that maximum — this both honors the spec and avoids a
            // UInt overflow on malformed input — but keep consuming
            // continuation bytes so the stream stays in sync.
            if varlen > (Self.maxVarlen >> 7) {
                clamped = true
            } else {
                varlen = (varlen << 7) | UInt(byte & 0x7f)

                if varlen > Self.maxVarlen {
                    clamped = true
                }
            }

            if byte & 0x80 == 0 {
                break
            }
        }

        if clamped {
            diagnostics.append(.variableLengthQuantityClamped)

            return Self.maxVarlen
        }

        return varlen
    }

    private mutating func _skipExtraChunkData() {
        guard chunkBytesLeft > 0
        else { return }

        let available = data.count - currentIndex

        if Int(chunkBytesLeft) > available {
            currentIndex = data.count
        } else {
            currentIndex += Int(chunkBytesLeft)
        }

        chunkBytesLeft = 0
    }
}
