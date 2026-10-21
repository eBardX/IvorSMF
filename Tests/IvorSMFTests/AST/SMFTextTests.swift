// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorSMF
import Testing
import XestiTools

struct SMFTextTests {
}

// MARK: -

extension SMFTextTests {
    @Test
    func bytesValue() {
        let text = SMFText(stringValue: "ABC")

        #expect(text?.bytesValue == [0x41, 0x42, 0x43])
    }

    @Test
    func bytesValue_c1ControlWithWindows1252Glyph_returnsNil() {
        // U+0093 is not in Windows-1252: byte 0x93 decodes to “ instead.
        #expect(SMFText(stringValue: "\u{93}")?.bytesValue == nil)
    }

    @Test
    func bytesValue_nonWindows1252_returnsNil() {
        let text = SMFText(stringValue: "café🎵")

        #expect(text?.bytesValue == nil)
    }

    @Test
    func bytesValue_windows1252() {
        let text = SMFText(stringValue: "“café” – €5")

        #expect(text?.bytesValue == [0x93, 0x63, 0x61, 0x66, 0xe9, 0x94, 0x20, 0x96, 0x20, 0x80, 0x35])
    }

    @Test
    func codable() throws {
        let original = SMFText(stringValue: "Hello")!               // swiftlint:disable:this force_unwrapping
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SMFText.self,
                                               from: data)

        #expect(decoded == original)
    }

    @Test
    func codable_decodeFromRawValue() throws {
        let data = Data("\"Hello\"".utf8)
        let decoded = try JSONDecoder().decode(SMFText.self,
                                               from: data)

        #expect(decoded.stringValue == "Hello")
    }

    @Test
    func comparable() {
        let low = SMFText(stringValue: "A")!                        // swiftlint:disable:this force_unwrapping
        let low2 = SMFText(stringValue: "A")!                       // swiftlint:disable:this force_unwrapping
        let high = SMFText(stringValue: "B")!                       // swiftlint:disable:this force_unwrapping

        #expect(low < high)
        #expect(!(high < low))
        #expect(!(low < low2))
    }

    @Test
    func decodedString_shiftJIS() {
        let text = SMFText(bytesValue: [0x82, 0xa0])                // “あ” in Shift-JIS

        #expect(text?.decodedString(using: .shiftJIS) == "あ")
    }

    @Test
    func decodedString_utf16WithByteOrderMark() {
        let text = SMFText(bytesValue: [0xff, 0xfe, 0x42, 0x30])    // BOM + “あ” in UTF-16LE

        #expect(text?.decodedString(using: .utf16) == "あ")
    }

    @Test
    func description() {
        let text = SMFText(stringValue: "Hello")!                   // swiftlint:disable:this force_unwrapping

        #expect(text.description == "Hello")
    }

    @Test
    func equality() {
        let text1 = SMFText(stringValue: "Hello")
        let text2 = SMFText(stringValue: "Hello")

        #expect(text1 == text2)
    }

    @Test
    func hashable() {
        let set: Set<SMFText> = [SMFText(stringValue: "Hello")!,    // swiftlint:disable:this force_unwrapping
                                 SMFText(stringValue: "Hello")!,     // swiftlint:disable:this force_unwrapping
                                 SMFText(stringValue: "World")!]     // swiftlint:disable:this force_unwrapping

        #expect(set.count == 2)
    }

    @Test
    func inequality() {
        #expect(SMFText(stringValue: "Hello") != SMFText(stringValue: "World"))
    }

    @Test
    func init_bytesValue() {
        let text = SMFText(bytesValue: [0x48, 0x69])

        #expect(text != nil)
        #expect(text?.stringValue == "Hi")
    }

    @Test
    func init_bytesValue_empty() {
        // An empty payload is a valid SMF text value (e.g. a melisma
        // Lyric/Display meta-event, RP-017 §7).
        let text = SMFText(bytesValue: [])

        #expect(text != nil)
        #expect(text?.stringValue.isEmpty == true)
    }

    @Test
    func init_bytesValue_windows1252() {
        let text = SMFText(bytesValue: [0x93, 0x48, 0x69, 0x94, 0x99])

        #expect(text?.stringValue == "“Hi”™")
    }

    @Test
    func init_stringLiteral() {
        let text: SMFText = "Hello"

        #expect(text.stringValue == "Hello")
    }

    @Test
    func init_stringValue() {
        let text = SMFText(stringValue: "Hello")

        #expect(text != nil)
        #expect(text?.stringValue == "Hello")
    }

    @Test
    func init_stringValue_empty() {
        let text = SMFText(stringValue: "")

        #expect(text != nil)
        #expect(text?.stringValue.isEmpty == true)
    }

    @Test
    func roundTrip() {
        let text = SMFText(stringValue: "Test 123")
        let bytes = text?.bytesValue

        #expect(bytes != nil)

        let roundTripped = bytes.flatMap { SMFText(bytesValue: $0) }

        #expect(roundTripped?.stringValue == "Test 123")
    }

    @Test
    func roundTrip_allByteValues() {
        let bytes = (0...255).map { UInt8($0) }

        #expect(SMFText(bytesValue: bytes)?.bytesValue == bytes)
    }
}
