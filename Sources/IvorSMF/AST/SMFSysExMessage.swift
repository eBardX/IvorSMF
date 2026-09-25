// © 2025–2026 John Gary Pusey (see LICENSE.md)

/// An SMF system exclusive message.
public enum SMFSysExMessage {

    /// An escape sequence carrying arbitrary bytes.
    case escape([UInt8])

    /// A system exclusive message.
    case systemExclusive([UInt8])

    // MARK: Internal Initializers

    internal init?(statusByte: UInt8,
                   dataBytes: [UInt8]) {
        switch statusByte {
        case 0xf0:
            self = .systemExclusive(dataBytes)

        case 0xf7:
            self = .escape(dataBytes)

        default:
            return nil
        }
    }
}

// MARK: -

extension SMFSysExMessage {

    // MARK: Internal Instance Properties

    internal var dataBytes: [UInt8]? {
        switch self {
        case let .escape(dataBytes),
             let .systemExclusive(dataBytes):
            dataBytes
        }
    }

    internal var statusByte: UInt8? {
        switch self {
        case .escape:
            0xf7

        case .systemExclusive:
            0xf0
        }
    }
}

// MARK: - Equatable

extension SMFSysExMessage: Equatable {
}

// MARK: - Hashable

extension SMFSysExMessage: Hashable {
}

// MARK: - Sendable

extension SMFSysExMessage: Sendable {
}
