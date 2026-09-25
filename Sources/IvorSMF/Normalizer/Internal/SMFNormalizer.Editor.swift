// © 2026 John Gary Pusey (see LICENSE.md)

extension SMFNormalizer {

    // MARK: Internal Nested Types

    internal struct Editor {

        // MARK: Internal Initializers

        internal init(sequence: SMFSequence) {
            self.changes = []
            self.sequence = sequence
        }

        // MARK: Private Instance Properties

        private let sequence: SMFSequence

        private var changes: [Change]
    }
}

// MARK: -

extension SMFNormalizer.Editor {

    // MARK: Internal Instance Methods

    internal mutating func editSequence() -> (SMFSequence, [SMFNormalizer.Change]) {
        var tracks = sequence.tracks.enumerated().map { idx, track in
            _editTrack(track, at: idx)
        }
        var format = sequence.format

        if format == .format0,
           tracks.count > 1 {
            format = .format1

            changes.append(.coercedFormat(from: sequence.format,
                                          to: format))
        }

        if format == .format1,
           tracks.count > 1 {
            tracks = _relocateConductorEvents(tracks)
        }

        let normalized = SMFSequence(format: format,
                                     division: sequence.division,
                                     tracks: tracks,
                                     isNormalized: true,
                                     isValidated: false)

        return (normalized, changes)
    }

    // MARK: Private Instance Methods

    // Recomputes the End-of-Track tick as the maximum tick among the
    // provided musical events (or zero if there are none) and appends a
    // canonical trailing End-of-Track event.
    private func _canonicalize(_ musicalEvents: [SMFEvent]) -> SMFTrack {
        let eotTime = musicalEvents.map(\.eventTime).max() ?? .zero

        return SMFTrack(events: musicalEvents + [.meta(eotTime, .endOfTrack)])
    }

    private mutating func _canonicalizeEndOfTrack(_ events: [SMFEvent],
                                                  at trackIndex: Int) -> SMFTrack {
        let eotIndices = events.indices.filter { events[$0].isEndOfTrack }
        let isCanonical = eotIndices.count == 1 && eotIndices[0] == events.count - 1

        guard !isCanonical
        else { return SMFTrack(events: events) }

        changes.append(eotIndices.isEmpty
                       ? .insertedEndOfTrack(trackIndex: trackIndex)
                       : .relocatedEndOfTrack(trackIndex: trackIndex))

        return _canonicalize(events.filter { !$0.isEndOfTrack })
    }

    private mutating func _editTrack(_ track: SMFTrack,
                                     at trackIndex: Int) -> SMFTrack {
        let events = _relocateSequenceNumber(track.events, at: trackIndex)

        return _canonicalizeEndOfTrack(events, at: trackIndex)
    }

    // Moves every tempo and time-signature meta-event out of tracks other
    // than track 0 and into track 0, at its original tick, per the format-1
    // convention that only the first track carries these events.
    private mutating func _relocateConductorEvents(_ tracks: [SMFTrack]) -> [SMFTrack] {
        var conductorEvents: [SMFEvent] = []
        var editedTracks = tracks

        for trackIndex in tracks.indices.dropFirst() {
            var tempoMoved = false
            var timeSignatureMoved = false

            let remainingEvents = tracks[trackIndex].events.filter { event in
                guard case let .meta(_, message) = event
                else { return true }

                switch message {
                case .tempo:
                    tempoMoved = true
                    conductorEvents.append(event)
                    return false

                case .timeSignature:
                    timeSignatureMoved = true
                    conductorEvents.append(event)
                    return false

                default:
                    return true
                }
            }

            if tempoMoved {
                changes.append(.relocatedTempo(trackIndex: trackIndex))
            }

            if timeSignatureMoved {
                changes.append(.relocatedTimeSignature(trackIndex: trackIndex))
            }

            if tempoMoved || timeSignatureMoved {
                editedTracks[trackIndex] = SMFTrack(events: remainingEvents)
            }
        }

        if !conductorEvents.isEmpty {
            let musicalEvents = editedTracks[0].events.filter { !$0.isEndOfTrack } + conductorEvents

            editedTracks[0] = _canonicalize(musicalEvents)
        }

        return editedTracks
    }

    private mutating func _relocateSequenceNumber(_ events: [SMFEvent],
                                                  at trackIndex: Int) -> [SMFEvent] {
        var changed = false

        let updated = events.map { event -> SMFEvent in
            guard case let .meta(eventTime, .sequenceNumber(seqNum)) = event,
                  eventTime != .zero
            else { return event }

            changed = true

            return .meta(.zero, .sequenceNumber(seqNum))
        }

        guard changed
        else { return events }

        changes.append(.relocatedSequenceNumber(trackIndex: trackIndex))

        return updated
    }
}
