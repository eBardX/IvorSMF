// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension SMFParser {

    // MARK: Public Nested Types

    /// An error that occurs when parsing SMF binary data.
    public enum Error {

        /// The input data ended before parsing was complete.
        case dataExhaustedPrematurely

        /// A MIDI channel message with an invalid status byte or data bytes.
        case invalidChannelMessage(UInt8, [UInt8])

        /// A chunk type identifier that is not a valid four-character ASCII
        /// string.
        case invalidChunkType(String)

        /// A time division that cannot be decoded from its byte representation.
        case invalidDivision([UInt8])

        /// An event time value that exceeds the valid range.
        case invalidEventTime(UInt)

        /// An SMF format value that cannot be decoded from its byte
        /// representation.
        case invalidFormat([UInt8])

        /// A meta-event with an unrecognized type byte or invalid data bytes.
        case invalidMetaMessage(UInt8, UInt8, [UInt8])

        /// A system exclusive message with invalid data bytes.
        case invalidSysExMessage(UInt8, [UInt8])

        /// The required SMF header chunk was not found.
        case missingHeaderChunk

        /// More than one SMF header chunk was found.
        case tooManyHeaderChunks

        /// A MIDI data byte was encountered where a status byte was expected.
        case unexpectedDataByte(UInt8)

        /// A MIDI channel message status byte that is not recognized.
        case unknownChannelMessageStatus(UInt8)

        /// An SMF event status byte that is not recognized.
        case unknownEventStatus(UInt8)
    }
}

// MARK: - EnhancedError

extension SMFParser.Error: EnhancedError {

    // MARK: Public Instance Properties

    /// The error category identifying the source module.
    public var category: Category? {
        Category("IvorSMF")
    }

    /// A human-readable description of this error.
    public var message: String {
        switch self {
        case .dataExhaustedPrematurely:
            "Data exhausted prematurely"

        case let .invalidChannelMessage(status, data):
            "Invalid MIDI channel message, status: \(status.hex), data: \(data.hex)"

        case let .invalidChunkType(chunkType):
            "Invalid SMF chunk type: '\(chunkType)'"

        case let .invalidDivision(bytesValue):
            "Invalid SMF division: \(bytesValue.hex)"

        case let .invalidEventTime(eventTime):
            "Invalid SMF event time: \(eventTime)"

        case let .invalidFormat(bytesValue):
            "Invalid SMF format: \(bytesValue.hex)"

        case let .invalidMetaMessage(status, type, data):
            "Invalid SMF meta-event message, status: \(status.hex), type: \(type.hex), data: \(data.hex)"

        case let .invalidSysExMessage(status, data):
            "Invalid SMF sysex message, status: \(status.hex), data: \(data.hex)"

        case .missingHeaderChunk:
            "Missing required SMF header chunk"

        case .tooManyHeaderChunks:
            "Too many SMF header chunks"

        case let .unexpectedDataByte(byte):
            "Unexpected MIDI data byte: \(byte.hex)"

        case let .unknownChannelMessageStatus(status):
            "Unknown MIDI channel message status: \(status.hex)"

        case let .unknownEventStatus(status):
            "Unknown SMF event status: \(status.hex)"
        }
    }
}

// MARK: - Equatable

extension SMFParser.Error: Equatable {
}

// MARK: - Sendable

extension SMFParser.Error: Sendable {
}
