// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorSMF
import Testing
import XestiTools

struct SMFTickRateTests {
}

// MARK: -

extension SMFTickRateTests {
    @Test
    func bytesValue() {
        #expect(SMFTickRate(uintValue: 0)?.bytesValue == [0x00, 0x00])
        #expect(SMFTickRate(uintValue: 480)?.bytesValue == [0x01, 0xe0])
        #expect(SMFTickRate(uintValue: 32_767)?.bytesValue == [0x7f, 0xff])
    }

    @Test
    func codable() throws {
        let original = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SMFTickRate.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_decodeFromRawValue() throws {
        let data = Data("480".utf8)
        let decoded = try JSONDecoder().decode(SMFTickRate.self,
                                               from: data)

        #expect(decoded.uintValue == 480)
    }

    @Test
    func codable_decodeInvalidValueThrows() {
        let data = Data("32768".utf8)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(SMFTickRate.self,
                                     from: data)
        }
    }

    @Test
    func comparable() {
        let low = SMFTickRate(uintValue: 96)!                       // swiftlint:disable:this force_unwrapping
        let low2 = SMFTickRate(uintValue: 96)!                      // swiftlint:disable:this force_unwrapping
        let high = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping

        #expect(low < high)
        #expect(!(high < low))
        #expect(!(low < low2))
    }

    @Test
    func description() {
        let tickRate = SMFTickRate(uintValue: 480)!                 // swiftlint:disable:this force_unwrapping

        #expect(tickRate.description == "480")
    }

    @Test
    func equality() {
        let tickRate1 = SMFTickRate(uintValue: 480)
        let tickRate2 = SMFTickRate(uintValue: 480)

        #expect(tickRate1 == tickRate2)
    }

    @Test
    func hashable() {
        let set: Set<SMFTickRate> = [SMFTickRate(uintValue: 480)!,  // swiftlint:disable:this force_unwrapping
                                     SMFTickRate(uintValue: 480)!,   // swiftlint:disable:this force_unwrapping
                                     SMFTickRate(uintValue: 96)!]    // swiftlint:disable:this force_unwrapping

        #expect(set.count == 2)
    }

    @Test
    func inequality() {
        #expect(SMFTickRate(uintValue: 480) != SMFTickRate(uintValue: 96))
    }

    @Test
    func init_bytesValue() {
        let tickRate = SMFTickRate(bytesValue: [0x01, 0xe0])

        #expect(tickRate != nil)
        #expect(tickRate?.uintValue == 480)
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMFTickRate(bytesValue: []) == nil)
        #expect(SMFTickRate(bytesValue: [0x00]) == nil)
        #expect(SMFTickRate(bytesValue: [0x00, 0x00, 0x00]) == nil)
    }

    @Test
    func init_integerLiteral() {
        let tickRate: SMFTickRate = 480

        #expect(tickRate.uintValue == 480)
    }

    @Test
    func init_uintValue() {
        #expect(SMFTickRate(uintValue: 0) != nil)
        #expect(SMFTickRate(uintValue: 480) != nil)
        #expect(SMFTickRate(uintValue: 32_767) != nil)
    }

    @Test
    func init_uintValue_invalid() {
        #expect(SMFTickRate(uintValue: 32_768) == nil)
    }

    @Test
    func isValid() {
        #expect(SMFTickRate.isValid(0))
        #expect(SMFTickRate.isValid(480))
        #expect(SMFTickRate.isValid(32_767))
        #expect(!SMFTickRate.isValid(32_768))
    }

    @Test
    func roundTrip() {
        let tickRate = SMFTickRate(uintValue: 960)
        let bytes = tickRate?.bytesValue

        #expect(bytes != nil)

        let roundTripped = bytes.flatMap { SMFTickRate(bytesValue: $0) }

        #expect(roundTripped?.uintValue == 960)
    }
}
