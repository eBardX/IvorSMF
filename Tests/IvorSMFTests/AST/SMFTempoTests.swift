// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorSMF
import Testing
import XestiTools

struct SMFTempoTests {
}

// MARK: -

extension SMFTempoTests {
    @Test
    func bytesValue() {
        let tempo = SMFTempo(uintValue: 500_000)

        #expect(tempo?.bytesValue == [0x07, 0xa1, 0x20])
    }

    @Test
    func bytesValue_zero() {
        let tempo = SMFTempo(uintValue: 0)

        #expect(tempo?.bytesValue == [0x00, 0x00, 0x00])
    }

    @Test
    func codable() throws {
        let original = SMFTempo(uintValue: 500_000)!                // swiftlint:disable:this force_unwrapping
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SMFTempo.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_decodeFromRawValue() throws {
        let data = Data("500000".utf8)
        let decoded = try JSONDecoder().decode(SMFTempo.self,
                                               from: data)

        #expect(decoded.uintValue == 500_000)
    }

    @Test
    func codable_decodeInvalidValueThrows() {
        let data = Data("16777216".utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SMFTempo.self,
                                     from: data)
        }
    }

    @Test
    func comparable() {
        let low = SMFTempo(uintValue: 100)!                         // swiftlint:disable:this force_unwrapping
        let low2 = SMFTempo(uintValue: 100)!                        // swiftlint:disable:this force_unwrapping
        let high = SMFTempo(uintValue: 200)!                        // swiftlint:disable:this force_unwrapping

        #expect(low < high)
        #expect(!(high < low))
        #expect(!(low < low2))
    }

    @Test
    func description() {
        let tempo = SMFTempo(uintValue: 500_000)!                   // swiftlint:disable:this force_unwrapping

        #expect(tempo.description == "500000")
    }

    @Test
    func equality() {
        let tempo1 = SMFTempo(uintValue: 500_000)
        let tempo2 = SMFTempo(uintValue: 500_000)

        #expect(tempo1 == tempo2)
    }

    @Test
    func hashable() {
        let set: Set<SMFTempo> = [SMFTempo(uintValue: 500_000)!,    // swiftlint:disable:this force_unwrapping
                                  SMFTempo(uintValue: 500_000)!,     // swiftlint:disable:this force_unwrapping
                                  SMFTempo(uintValue: 600_000)!]     // swiftlint:disable:this force_unwrapping

        #expect(set.count == 2)
    }

    @Test
    func inequality() {
        #expect(SMFTempo(uintValue: 500_000) != SMFTempo(uintValue: 600_000))
    }

    @Test
    func init_bytesValue() {
        let tempo = SMFTempo(bytesValue: [0x07, 0xa1, 0x20])

        #expect(tempo != nil)
        #expect(tempo?.uintValue == 500_000)
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMFTempo(bytesValue: []) == nil)
        #expect(SMFTempo(bytesValue: [0x00, 0x00]) == nil)
        #expect(SMFTempo(bytesValue: [0x00, 0x00, 0x00, 0x00]) == nil)
    }

    @Test
    func init_integerLiteral() {
        let tempo: SMFTempo = 500_000

        #expect(tempo.uintValue == 500_000)
    }

    @Test
    func init_uintValue() {
        #expect(SMFTempo(uintValue: 0) != nil)
        #expect(SMFTempo(uintValue: 500_000) != nil)
        #expect(SMFTempo(uintValue: 16_777_215) != nil)
    }

    @Test
    func init_uintValue_invalid() {
        #expect(SMFTempo(uintValue: 16_777_216) == nil)
    }

    @Test
    func isValid() {
        #expect(SMFTempo.isValid(0))
        #expect(SMFTempo.isValid(500_000))
        #expect(SMFTempo.isValid(16_777_215))
        #expect(!SMFTempo.isValid(16_777_216))
    }

    @Test
    func roundTrip() {
        let tempo = SMFTempo(uintValue: 600_000)
        let bytes = tempo?.bytesValue

        #expect(bytes != nil)

        let roundTripped = bytes.flatMap { SMFTempo(bytesValue: $0) }

        #expect(roundTripped?.uintValue == 600_000)
    }
}
