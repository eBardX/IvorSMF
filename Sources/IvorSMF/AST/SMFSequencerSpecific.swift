// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI

/// The payload of an SMF Sequencer-Specific meta-event: a manufacturer ID
/// followed by data whose meaning that manufacturer defines.
public struct SMFSequencerSpecific {

    // MARK: Public Initializers

    /// Creates a new `SMFSequencerSpecific` instance with the provided
    /// manufacturer ID and data, or `nil` if the manufacturer ID is not valid.
    ///
    /// - Parameter manufacturerID: The manufacturer ID. Must be either one
    ///                             nonzero 7-bit byte, or three 7-bit bytes
    ///                             starting with zero.
    /// - Parameter data:           The manufacturer-defined data.
    public init?(manufacturerID: [UInt8],
                 data: [UInt8]) {
        guard Self.isValidManufacturerID(manufacturerID)
        else { return nil }

        self.data = data
        self.manufacturerID = manufacturerID
    }

    // MARK: Public Instance Properties

    /// The manufacturer-defined data that follows the manufacturer ID.
    public let data: [UInt8]

    /// The manufacturer ID: either one byte, or three bytes starting with
    /// zero.
    public let manufacturerID: [UInt8]
}

// MARK: -

extension SMFSequencerSpecific {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided bytes form a
    /// valid manufacturer ID.
    ///
    /// - Parameter manufacturerID: The bytes to validate.
    ///
    /// - Returns:  `true` if the bytes are either one nonzero 7-bit byte, or
    ///             three 7-bit bytes starting with zero; otherwise, `false`.
    public static func isValidManufacturerID(_ manufacturerID: [UInt8]) -> Bool {
        guard manufacturerID.allSatisfy({ $0 < 0x80 }),
              let first = manufacturerID.first
        else { return false }

        return manufacturerID.count == (first == 0 ? 3 : 1)
    }
}

// MARK: - Equatable

extension SMFSequencerSpecific: Equatable {
}

// MARK: - Hashable

extension SMFSequencerSpecific: Hashable {
}

// MARK: - MIDIBytesConvertible

extension SMFSequencerSpecific: MIDIBytesConvertible {

    // MARK: Public Initializers

    /// Creates an `SMFSequencerSpecific` instance from its SMF encoding, or
    /// `nil` if the bytes do not start with a valid manufacturer ID.
    ///
    /// - Parameter bytesValue: The manufacturer ID (one byte, or three bytes if
    ///                         the first is zero), followed by the data.
    public init?(bytesValue: [UInt8]) {
        let idCount = bytesValue.first == 0 ? 3 : 1

        guard bytesValue.count >= idCount
        else { return nil }

        self.init(manufacturerID: Array(bytesValue.prefix(idCount)),
                  data: Array(bytesValue.dropFirst(idCount)))
    }

    // MARK: Public Instance Properties

    /// The SMF encoding of this payload: the manufacturer ID followed by the
    /// data. Never `nil`, because every valid payload can be encoded.
    public var bytesValue: [UInt8]? {
        manufacturerID + data
    }
}

// MARK: - Sendable

extension SMFSequencerSpecific: Sendable {
}
