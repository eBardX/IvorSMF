// © 2026 John Gary Pusey (see LICENSE.md)

internal import Foundation
internal import IvorMIDI

private import XestiTools

extension SMFFormatter {

    // MARK: Internal Nested Types

    internal struct Writer {

        // MARK: Internal Initializers

        internal init(sequence: SMFSequence) {
            self.chunkMode = false
            self.currentTime = 0
            self.outChunkData = Data()
            self.outData = Data()
            self.runningStatus = 0
            self.sequence = sequence
        }

        // MARK: Private Instance Properties

        private let sequence: SMFSequence

        private var chunkMode: Bool
        private var currentTime: UInt
        private var outChunkData: Data
        private var outData: Data
        private var runningStatus: UInt8
    }
}

// MARK: -

extension SMFFormatter.Writer {

    // MARK: Internal Instance Methods

    // A validated sequence is guaranteed encodable, so this never fails; the
    // preconditions below exist only to catch a validator/writer invariant
    // mismatch.
    internal mutating func writeSequence() -> Data {
        _writeHeader(sequence.format,
                     UInt(sequence.tracks.count),
                     sequence.division)

        sequence.tracks.forEach {
            _writeTrack($0)
        }

        let data = outData

        outData.removeAll()

        return data
    }

    // MARK: Private Instance Methods

    private mutating func _writeAsByte(_ value: UInt) {
        guard let byte = UInt8(exactly: value)
        else { preconditionFailure("Bad byte: \(value)") }

        _writeByte(byte)
    }

    private mutating func _writeAsWord(_ value: UInt) {
        guard (0...0xffff).contains(value)
        else { preconditionFailure("Bad word: \(value)") }

        _writeAsByte(value >> 8)
        _writeAsByte(value & 0xff)
    }

    private mutating func _writeByte(_ byte: UInt8) {
        if chunkMode {
            outChunkData.append(byte)
        } else {
            outData.append(byte)
        }
    }

    private mutating func _writeBytes(_ bytes: [UInt8]) {
        bytes.forEach {
            _writeByte($0)
        }
    }

    private mutating func _writeChunk(_ chunkType: SMFChunkType) {
        chunkMode = false

        _writeChunkType(chunkType)
        _writeChunkLength(UInt(outChunkData.count))

        outData.append(outChunkData)

        outChunkData.removeAll(keepingCapacity: true)
    }

    private mutating func _writeChunkLength(_ chunkLength: UInt) {
        guard (0...0x7fffffff).contains(chunkLength)
        else { preconditionFailure("Bad chunk length: \(chunkLength)") }

        _writeAsByte(chunkLength >> 24)
        _writeAsByte((chunkLength >> 16) & 0xff)
        _writeAsByte((chunkLength >> 8) & 0xff)
        _writeAsByte(chunkLength & 0xff)
    }

    private mutating func _writeChunkType(_ chunkType: SMFChunkType) {
        for char in chunkType.stringValue {
            guard let byte = char.asciiValue
            else { preconditionFailure("Bad chunk type: '\(chunkType)'") }

            _writeByte(byte)
        }
    }

    private mutating func _writeEvent(_ event: SMFEvent) {
        _writeEventTime(event.eventTime)

        switch event {
        case let .meta(_, message):
            guard let statusByte = message.statusByte,
                  let typeByte = message.typeByte,
                  let dataBytes = message.dataBytes
            else { preconditionFailure("Bad event: \(event)") }

            runningStatus = 0

            _writeByte(statusByte)
            _writeByte(typeByte)
            _writeVarlen(UInt(dataBytes.count))
            _writeBytes(dataBytes)

        case let .midi(_, message):
            guard let statusByte = message.statusByte,
                  let dataBytes = message.dataBytes
            else { preconditionFailure("Bad event: \(event)") }

            if runningStatus != statusByte {
                runningStatus = statusByte

                _writeByte(statusByte)
            }

            _writeBytes(dataBytes)

        case let .sysEx(_, message):
            guard let statusByte = message.statusByte,
                  let dataBytes = message.dataBytes
            else { preconditionFailure("Bad event: \(event)") }

            runningStatus = 0

            _writeByte(statusByte)
            _writeVarlen(UInt(dataBytes.count))
            _writeBytes(dataBytes)
        }
    }

    private mutating func _writeEventTime(_ eventTime: SMFEventTime) {
        let deltaTime = eventTime.uintValue - currentTime

        currentTime = eventTime.uintValue

        _writeVarlen(deltaTime)
    }

    private mutating func _writeHeader(_ format: SMFFormat,
                                       _ trackCount: UInt,
                                       _ division: SMFDivision) {
        guard let fmtBytes = format.bytesValue
        else { preconditionFailure("Bad format: \(format)") }

        guard (format == .format0 && trackCount == 1)
              || (format != .format0 && (1...0xffff).contains(trackCount))
        else { preconditionFailure("Bad track count: \(trackCount)") }

        guard let divBytes = division.bytesValue
        else { preconditionFailure("Bad division: \(division)") }

        chunkMode = true

        _writeBytes(fmtBytes)
        _writeAsWord(trackCount)
        _writeBytes(divBytes)

        _writeChunk(.header)
    }

    private mutating func _writeTrack(_ track: SMFTrack) {
        chunkMode = true
        currentTime = 0
        runningStatus = 0

        track.events.forEach {
            _writeEvent($0)
        }

        _writeChunk(.track)
    }

    private mutating func _writeVarlen(_ varlen: UInt) {
        guard (0...0x0fffffff).contains(varlen)
        else { preconditionFailure("Bad varlen: \(varlen)") }

        var stack: [UInt] = []
        var varlen = varlen

        stack.push(varlen & 0x7f)

        for _ in 1..<4 {
            varlen >>= 7

            guard varlen > 0
            else { break }

            stack.push((varlen & 0x7f) | 0x80)
        }

        while let value = stack.pop() {
            _writeAsByte(value)
        }
    }
}
