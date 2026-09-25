// © 2025–2026 John Gary Pusey (see LICENSE.md)

extension UInt8 {

    // MARK: Internal Instance Properties

    internal var hex: String {
        let hexString = String(self,
                               radix: 16,
                               uppercase: true)

        if hexString.count < 2 {
            return "0" + hexString
        }

        return hexString
    }

    internal var isMetaEventStatusByte: Bool {
        self == 0xff
    }

    internal var isMIDIEventStatusByte: Bool {
        [0x80, 0x90, 0xa0, 0xb0, 0xc0, 0xd0, 0xe0].contains(self & 0xf0)
    }

    internal var isMIDIStatusByte: Bool {
        (0x80...0xff).contains(self)
    }

    internal var isSysExEventStatusByte: Bool {
        [0xf0, 0xf7].contains(self)
    }

    internal var isSystemRealTimeByte: Bool {
        (0xf8...0xfe).contains(self)
    }
}
