// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFTimeSignatureTests {
}

// MARK: -

extension SMFTimeSignatureTests {
    @Test
    func bytesValue() {
        let timeSig = SMFTimeSignature(numerator: 4,
                                       denominator: 2,
                                       clocksPerClick: 24,
                                       thirtySecondsPerQuarter: 8)

        #expect(timeSig?.bytesValue == [0x04, 0x02, 0x18, 0x08])
    }

    @Test
    func default_is4_4() {
        let timeSig = SMFTimeSignature.default

        #expect(timeSig.bytesValue == [0x04, 0x02, 0x18, 0x08])
    }

    @Test
    func equality() {
        let timeSig1 = SMFTimeSignature(numerator: 4,
                                        denominator: 2,
                                        clocksPerClick: 24,
                                        thirtySecondsPerQuarter: 8)!  // swiftlint:disable:this force_unwrapping
        let timeSig2 = SMFTimeSignature(numerator: 4,
                                        denominator: 2,
                                        clocksPerClick: 24,
                                        thirtySecondsPerQuarter: 8)!  // swiftlint:disable:this force_unwrapping

        #expect(timeSig1 == timeSig2)
    }

    @Test
    func hashable() {
        let timeSig1 = SMFTimeSignature(numerator: 4,
                                        denominator: 2,
                                        clocksPerClick: 24,
                                        thirtySecondsPerQuarter: 8)!  // swiftlint:disable:this force_unwrapping
        let timeSig2 = SMFTimeSignature(numerator: 4,
                                        denominator: 2,
                                        clocksPerClick: 24,
                                        thirtySecondsPerQuarter: 8)!  // swiftlint:disable:this force_unwrapping
        let set: Set<SMFTimeSignature> = [timeSig1, timeSig2]

        #expect(set.count == 1)
    }

    @Test
    func inequality_differentNumerator() {
        let timeSig1 = SMFTimeSignature(numerator: 4,
                                        denominator: 2,
                                        clocksPerClick: 24,
                                        thirtySecondsPerQuarter: 8)!  // swiftlint:disable:this force_unwrapping
        let timeSig2 = SMFTimeSignature(numerator: 3,
                                        denominator: 2,
                                        clocksPerClick: 24,
                                        thirtySecondsPerQuarter: 8)!  // swiftlint:disable:this force_unwrapping

        #expect(timeSig1 != timeSig2)
    }

    @Test
    func init_bytesValue() {
        let timeSig = SMFTimeSignature(bytesValue: [0x03, 0x03, 0x18, 0x08])

        #expect(timeSig != nil)
        #expect(timeSig?.numerator == 3)
        #expect(timeSig?.denominator == 3)
        #expect(timeSig?.clocksPerClick == 24)
        #expect(timeSig?.thirtySecondsPerQuarter == 8)
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMFTimeSignature(bytesValue: []) == nil)
        #expect(SMFTimeSignature(bytesValue: [0x04, 0x02, 0x18]) == nil)
        #expect(SMFTimeSignature(bytesValue: [0x04, 0x02, 0x18, 0x08, 0x00]) == nil)
    }

    @Test
    func init_invalid_thirtySecondsPerQuarter() {
        #expect(SMFTimeSignature(numerator: 4, denominator: 2, clocksPerClick: 24, thirtySecondsPerQuarter: 0) == nil)
    }

    @Test
    func init_invalid_clocksPerClick() {
        #expect(SMFTimeSignature(numerator: 4, denominator: 2, clocksPerClick: 0, thirtySecondsPerQuarter: 8) == nil)
    }

    @Test
    func init_invalid_denominator() {
        #expect(SMFTimeSignature(numerator: 4, denominator: 256, clocksPerClick: 24, thirtySecondsPerQuarter: 8) == nil)
    }

    @Test
    func init_invalid_numerator() {
        #expect(SMFTimeSignature(numerator: 0, denominator: 2, clocksPerClick: 24, thirtySecondsPerQuarter: 8) == nil)
    }

    @Test
    func init_valid_denominator_one() {
        let timeSig = SMFTimeSignature(numerator: 4, denominator: 1, clocksPerClick: 24, thirtySecondsPerQuarter: 8)

        #expect(timeSig != nil)
        #expect(timeSig?.denominator == 1)
    }

    @Test
    func init_valid_denominator_zero() {
        let timeSig = SMFTimeSignature(numerator: 4, denominator: 0, clocksPerClick: 24, thirtySecondsPerQuarter: 8)

        #expect(timeSig != nil)
        #expect(timeSig?.denominator == 0)
    }

    @Test
    func init_validValues() {
        let timeSig = SMFTimeSignature(numerator: 4,
                                       denominator: 2,
                                       clocksPerClick: 24,
                                       thirtySecondsPerQuarter: 8)

        #expect(timeSig != nil)
        #expect(timeSig?.numerator == 4)
        #expect(timeSig?.denominator == 2)
        #expect(timeSig?.clocksPerClick == 24)
        #expect(timeSig?.thirtySecondsPerQuarter == 8)
    }

    @Test
    func roundTrip() {
        let timeSig = SMFTimeSignature(numerator: 6,
                                       denominator: 3,
                                       clocksPerClick: 36,
                                       thirtySecondsPerQuarter: 8)
        let bytes = timeSig?.bytesValue

        #expect(bytes != nil)

        let roundTripped = bytes.flatMap { SMFTimeSignature(bytesValue: $0) }

        #expect(roundTripped?.numerator == 6)
        #expect(roundTripped?.denominator == 3)
        #expect(roundTripped?.clocksPerClick == 36)
        #expect(roundTripped?.thirtySecondsPerQuarter == 8)
    }
}
