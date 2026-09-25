// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing
import XestiTools

struct SMFFormatterErrorTests {
}

// MARK: -

extension SMFFormatterErrorTests {
    @Test
    func category() {
        let error = SMFFormatter.Error.notValidated

        #expect(error.category?.description == "IvorSMF")
    }

    @Test
    func message_notValidated() {
        let error = SMFFormatter.Error.notValidated

        #expect(!error.message.isEmpty)
    }
}
