// © 2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorSMF

func loadFixture(_ name: String,
                 extension ext: String) throws -> Data {
    let url = Bundle.module.url(forResource: name, withExtension: ext)!  // swiftlint:disable:this force_unwrapping

    return try Data(contentsOf: url)
}

func makeFormat0Data() -> Data {
    var bytes: [UInt8] = []

    bytes += [0x4d, 0x54, 0x68, 0x64]
    bytes += [0x00, 0x00, 0x00, 0x06]
    bytes += [0x00, 0x00]
    bytes += [0x00, 0x01]
    bytes += [0x01, 0xe0]

    bytes += [0x4d, 0x54, 0x72, 0x6b]
    bytes += [0x00, 0x00, 0x00, 0x14]
    bytes += [0x00, 0xff, 0x51, 0x03, 0x07, 0xa1, 0x20]
    bytes += [0x00, 0x90, 0x3c, 0x64]
    bytes += [0x83, 0x60, 0x80, 0x3c, 0x40]
    bytes += [0x00, 0xff, 0x2f, 0x00]

    return Data(bytes)
}

func makeHeaderBytes(format: UInt16,
                     ntrks: UInt16,
                     division: UInt16) -> [UInt8] {
    var bytes: [UInt8] = []

    bytes += [0x4d, 0x54, 0x68, 0x64]
    bytes += [0x00, 0x00, 0x00, 0x06]
    bytes += [UInt8(format >> 8), UInt8(format & 0xff)]
    bytes += [UInt8(ntrks >> 8), UInt8(ntrks & 0xff)]
    bytes += [UInt8(division >> 8), UInt8(division & 0xff)]

    return bytes
}

func makeSequence(format: SMFFormat = .format0,
                  tracks: [SMFTrack]) -> SMFSequence {
    let tickRate = SMFTickRate(uintValue: 96)!  // swiftlint:disable:this force_unwrapping

    return SMFSequence(format: format,
                       division: .metrical(tickRate),
                       tracks: tracks)
}

func makeTrackBytes(_ content: [UInt8]) -> [UInt8] {
    let length = UInt32(content.count)
    var bytes: [UInt8] = []

    bytes += [0x4d, 0x54, 0x72, 0x6b]
    bytes += [UInt8(length >> 24),
              UInt8((length >> 16) & 0xff),
              UInt8((length >> 8) & 0xff),
              UInt8(length & 0xff)]
    bytes += content

    return bytes
}

func makeValidatedSequence(_ sequence: SMFSequence) throws -> SMFSequence {
    let (normalized, _) = SMFNormalizer().normalize(sequence)
    let (validated, _) = try SMFValidator().validate(normalized)

    return validated
}
