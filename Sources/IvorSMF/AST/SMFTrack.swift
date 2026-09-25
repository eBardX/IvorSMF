// © 2025–2026 John Gary Pusey (see LICENSE.md)

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

// MARK: - Equatable

extension SMFTrack: Equatable {
}

// MARK: - Hashable

extension SMFTrack: Hashable {
}

// MARK: - Sendable

extension SMFTrack: Sendable {
}
