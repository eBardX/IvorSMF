// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing
import XestiTools

struct SMFParserErrorTests {
}

// MARK: -

extension SMFParserErrorTests {
    @Test
    func category() {
        let error = SMFParser.Error.dataExhaustedPrematurely

        #expect(error.category?.description == "IvorSMF")
    }

    @Test
    func message_dataExhaustedPrematurely() {
        let error = SMFParser.Error.dataExhaustedPrematurely

        #expect(error.message == "Data exhausted prematurely")
    }

    @Test
    func message_invalidChannelMessage() {
        let error = SMFParser.Error.invalidChannelMessage(0x90, [0x3c])

        #expect(error.message.contains("90"))
    }

    @Test
    func message_invalidChunkType() {
        let error = SMFParser.Error.invalidChunkType("XXXX")

        #expect(error.message.contains("XXXX"))
    }

    @Test
    func message_invalidDivision() {
        let error = SMFParser.Error.invalidDivision([0xe0, 0x00])

        #expect(!error.message.isEmpty)
    }

    @Test
    func message_invalidEventTime() {
        let error = SMFParser.Error.invalidEventTime(0x80000000)

        #expect(error.message.contains("2147483648"))
    }

    @Test
    func message_invalidFormat() {
        let error = SMFParser.Error.invalidFormat([0x00, 0x03])

        #expect(!error.message.isEmpty)
    }

    @Test
    func message_invalidMetaMessage() {
        let error = SMFParser.Error.invalidMetaMessage(0xff, 0x00, [0x00])

        #expect(!error.message.isEmpty)
    }

    @Test
    func message_invalidSysExMessage() {
        let error = SMFParser.Error.invalidSysExMessage(0xf0, [0x00])

        #expect(!error.message.isEmpty)
    }

    @Test
    func message_missingHeaderChunk() {
        let error = SMFParser.Error.missingHeaderChunk

        #expect(!error.message.isEmpty)
    }

    @Test
    func message_tooManyHeaderChunks() {
        let error = SMFParser.Error.tooManyHeaderChunks

        #expect(!error.message.isEmpty)
    }

    @Test
    func message_unexpectedDataByte() {
        let error = SMFParser.Error.unexpectedDataByte(0x3c)

        #expect(error.message.contains("3C"))
    }

    @Test
    func message_unknownChannelMessageStatus() {
        let error = SMFParser.Error.unknownChannelMessageStatus(0xf0)

        #expect(error.message.contains("F0"))
    }

    @Test
    func message_unknownEventStatus() {
        let error = SMFParser.Error.unknownEventStatus(0xf5)

        #expect(error.message.contains("F5"))
    }
}
