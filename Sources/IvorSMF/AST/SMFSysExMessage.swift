// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI

private import XestiTools

/// An SMF system exclusive message.
///
/// A system exclusive message may be stored as a single packet or split into
/// timed packets (RP-001 p.6). The first packet is always a
/// ``systemExclusive(_:)`` event; each later packet is a ``continuation(_:)``
/// event, and the final packet must end with 0xF7. Continuation and escape
/// events share the 0xF7 status byte, so they are told apart by context: an
/// 0xF7 event is a continuation only while a multi-packet message is still
/// open.
public enum SMFSysExMessage {

    /// A later packet of a multi-packet system exclusive message, carrying the
    /// bytes to be transmitted.
    case continuation([UInt8])

    /// An escape sequence carrying arbitrary bytes.
    case escape([UInt8])

    /// A system exclusive message, or the first packet of a multi-packet one,
    /// carrying the bytes to be transmitted after 0xF0.
    case systemExclusive([UInt8])

    // MARK: Internal Initializers

    internal init?(statusByte: UInt8,
                   dataBytes: [UInt8],
                   isContinuation: Bool = false) {
        switch statusByte {
        case 0xf0:
            self = .systemExclusive(dataBytes)

        case 0xf7:
            self = isContinuation ? .continuation(dataBytes) : .escape(dataBytes)

        default:
            return nil
        }
    }
}

// MARK: -

extension SMFSysExMessage {

    // MARK: Public Initializers

    /// Creates a new `SMFSysExMessage` instance that carries the provided MIDI
    /// system message.
    ///
    /// A system exclusive message, such as one built by an IvorMIDI universal
    /// system exclusive builder, becomes a single complete
    /// ``systemExclusive(_:)`` packet. Any other system message — a system
    /// common or system real-time message — becomes an ``escape(_:)``, which
    /// RP-001 (p.6) provides for transmitting these messages.
    ///
    /// - Parameter message:    The MIDI system message.
    public init(for message: MIDISystemMessage) {
        if case let .systemExclusive(dataBytes) = message {
            self = .systemExclusive(dataBytes)
        } else {
            self = .escape(message.bytesValue.require())
        }
    }

    // MARK: Public Instance Properties

    /// The MIDI system message that this event carries, or `nil` if it does not
    /// carry exactly one complete system message.
    ///
    /// A ``systemExclusive(_:)`` event carries a system exclusive message when
    /// it is a single complete packet ending with 0xF7. An ``escape(_:)`` event
    /// carries a system message when its bytes are exactly one system common or
    /// system real-time message, such as a song position pointer or an MTC
    /// quarter frame. A ``continuation(_:)`` packet is never a complete message.
    public var systemMessage: MIDISystemMessage? {
        switch self {
        case .continuation:
            nil

        case let .escape(dataBytes):
            MIDISystemMessage(bytesValue: dataBytes)

        case let .systemExclusive(dataBytes):
            MIDISystemMessage(statusByte: 0xf0,
                              dataBytes: dataBytes)
        }
    }

    // MARK: Internal Instance Properties

    internal var dataBytes: [UInt8]? {
        switch self {
        case let .continuation(dataBytes),
             let .escape(dataBytes),
             let .systemExclusive(dataBytes):
            dataBytes
        }
    }

    internal var isContinuation: Bool {
        if case .continuation = self {
            true
        } else {
            false
        }
    }

    // A packet is open-ended when it does not end with 0xF7, meaning that the
    // multi-packet message it belongs to continues in a later continuation
    // packet. An escape never opens or continues a multi-packet message.
    internal var isOpenEnded: Bool {
        switch self {
        case let .continuation(dataBytes),
             let .systemExclusive(dataBytes):
            dataBytes.last != 0xf7

        case .escape:
            false
        }
    }

    internal var statusByte: UInt8? {
        switch self {
        case .continuation,
             .escape:
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
