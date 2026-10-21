// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorMIDI

/// An SMF track containing a sequence of events.
public struct SMFTrack {

    // MARK: Public Initializers

    /// Creates a new `SMFTrack` instance with the provided events.
    ///
    /// The events are sorted by time on initialization; the caller does not need
    /// to provide them in order.
    ///
    /// - Parameter events: The events in this track.
    public init(events: [SMFEvent]) {
        self.events = events.sorted { $0.eventTime < $1.eventTime }
    }

    // MARK: Public Instance Properties

    /// The events in this track, sorted in time order.
    public let events: [SMFEvent]
}

// MARK: -

extension SMFTrack {

    // MARK: Public Instance Methods

    /// Returns the MIDI channel associated with the event at the provided
    /// index.
    ///
    /// A MIDI event is associated with its own channel. A meta-event or system
    /// exclusive event is associated with the channel of the most recent MIDI
    /// Channel Prefix meta-event, which stays in effect until the next MIDI
    /// event or the next MIDI Channel Prefix (RP-001 p.9).
    ///
    /// - Parameter index:  The index of the event in ``events``.
    ///
    /// - Returns:  The associated MIDI channel, or `nil` if the event is not
    ///             associated with any channel.
    public func channel(forEventAt index: Int) -> MIDIChannel? {
        if case let .midi(_, message) = events[index] {
            return message.channel
        }

        for event in events[...index].reversed() {
            switch event {
            case let .meta(_, .midiChannelPrefix(channel)):
                return channel

            case .midi:
                return nil

            case .meta,
                 .sysEx:
                continue
            }
        }

        return nil
    }
}

// MARK: - Equatable

extension SMFTrack: Equatable {
}

// MARK: - Hashable

extension SMFTrack: Hashable {
}

// MARK: - Sendable

extension SMFTrack: Sendable {
}
