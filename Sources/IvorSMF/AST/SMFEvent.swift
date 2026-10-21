// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI

/// An event in an SMF track.
public enum SMFEvent {

    /// A meta-event.
    case meta(SMFEventTime, SMFMetaMessage)

    /// A MIDI channel event.
    case midi(SMFEventTime, MIDIChannelMessage)

    /// A system exclusive event.
    case sysEx(SMFEventTime, SMFSysExMessage)
}

// MARK: -

extension SMFEvent {

    // MARK: Public Type Methods

    /// Returns MIDI events that carry the provided channel messages, all at the
    /// provided time, in the order given.
    ///
    /// Use this to place a sequence of messages that must be sent in order,
    /// such as the control changes returned by IvorMIDI’s
    /// `registeredParameterChange(_:value:on:)` and
    /// `nonRegisteredParameterChange(_:value:on:)` builders. ``SMFTrack`` keeps
    /// events at the same tick in the order given, so the sequence survives
    /// sorting.
    ///
    /// - Parameter messages:   The channel messages, in sending order.
    /// - Parameter eventTime:  The time of every returned event.
    ///
    /// - Returns:  One `.midi` event for each message.
    public static func midiEvents(for messages: [MIDIChannelMessage],
                                  at eventTime: SMFEventTime) -> [Self] {
        messages.map { .midi(eventTime, $0) }
    }

    // MARK: Public Instance Properties

    /// The absolute time of this event, measured in ticks from the
    /// beginning of the track.
    public var eventTime: SMFEventTime {
        switch self {
        case let .meta(eventTime, _),
             let .midi(eventTime, _),
             let .sysEx(eventTime, _):
            eventTime
        }
    }

    // MARK: Internal Instance Properties

    internal var isEndOfTrack: Bool {
        if case .meta(_, .endOfTrack) = self {
            true
        } else {
            false
        }
    }

    // A transmittable event is one whose bytes are sent over MIDI: a MIDI
    // event or a system exclusive event, but never a meta-event.
    internal var isTransmittable: Bool {
        switch self {
        case .meta:
            false

        case .midi,
             .sysEx:
            true
        }
    }
}

// MARK: - Equatable

extension SMFEvent: Equatable {
}

// MARK: - Hashable

extension SMFEvent: Hashable {
}

// MARK: - Sendable

extension SMFEvent: Sendable {
}
