// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import IvorSMPTE
import Testing

struct SMFDivisionTests {
}

// MARK: -

extension SMFDivisionTests {
    @Test
    func bytesValue_metrical() {
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping
        let division = SMFDivision.metrical(tickRate)

        #expect(division.bytesValue == [0x01, 0xe0])
    }

    @Test
    func bytesValue_timeCode() {
        let timeCode = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)!   // swiftlint:disable:this force_unwrapping
        let division = SMFDivision.timeCode(timeCode)

        #expect(division.bytesValue == [0xe8, 0x04])
    }

    @Test
    func equality() {
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping

        #expect(SMFDivision.metrical(tickRate) == .metrical(tickRate))
    }

    @Test
    func hashable() {
        let tickRate = SMFTickRate(uintValue: 480)!                     // swiftlint:disable:this force_unwrapping
        let set: Set<SMFDivision> = [.metrical(tickRate), .metrical(tickRate)]

        #expect(set.count == 1)
    }

    @Test
    func inequality_differentCase() {
        let tickRate = SMFTickRate(uintValue: 480)!                        // swiftlint:disable:this force_unwrapping
        let timeCode = SMFTimeCode(frameRate: .fps24, ticksPerFrame: 4)!   // swiftlint:disable:this force_unwrapping

        #expect(SMFDivision.metrical(tickRate) != .timeCode(timeCode))
    }

    @Test
    func init_bytesValue_invalidCount() {
        #expect(SMFDivision(bytesValue: []) == nil)
        #expect(SMFDivision(bytesValue: [0x00]) == nil)
        #expect(SMFDivision(bytesValue: [0x00, 0x00, 0x00]) == nil)
    }

    @Test
    func init_bytesValue_invalidTimeCode() {
        #expect(SMFDivision(bytesValue: [0xe0, 0x04]) == nil)
    }

    @Test
    func init_bytesValue_metrical() {
        let division = SMFDivision(bytesValue: [0x01, 0xe0])

        #expect(division != nil)

        if case let .metrical(tickRate) = division {
            #expect(tickRate.uintValue == 480)
        } else {
            Issue.record("Expected metrical division")
        }
    }

    @Test
    func init_bytesValue_timeCode() {
        let division = SMFDivision(bytesValue: [0xe8, 0x04])

        #expect(division != nil)

        if case let .timeCode(timeCode) = division {
            #expect(timeCode.frameRate == .fps24)
            #expect(timeCode.ticksPerFrame == 4)
        } else {
            Issue.record("Expected timeCode division")
        }
    }
}
