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
