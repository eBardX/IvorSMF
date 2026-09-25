// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing
import XestiTools

struct SMFValidatorErrorTests {
}

// MARK: -

extension SMFValidatorErrorTests {
    @Test
    func category() {
        let error = SMFValidator.Error.notNormalized

        #expect(error.category?.description == "IvorSMF")
    }

    @Test
    func message_notNormalized() {
        let error = SMFValidator.Error.notNormalized

        #expect(!error.message.isEmpty)
    }
}
