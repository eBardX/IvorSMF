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
        var format = sequence.format
        var tracks = sequence.tracks

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

        tracks = tracks.enumerated().map { idx, track in
            _editTrack(track, at: idx)
        }

        let normalized = SMFSequence(format: format,
                                     division: sequence.division,
                                     tracks: tracks,
                                     isNormalized: true,
                                     isValidated: false)

        return (normalized, changes)
    }

    // MARK: Private Type Methods

    // Returns the change that reports relocating the provided event to the
    // start of its track, or nil if the event is not one that RP-001 (p.8–9)
    // and RP-019 require to appear there: at time zero, before any
    // transmittable event.
    private static func _leadingEventChange(_ event: SMFEvent,
                                            at trackIndex: Int) -> SMFNormalizer.Change? {
        guard case let .meta(_, message) = event
        else { return nil }

        switch message {
        case .deviceName:
            return .relocatedDeviceName(trackIndex: trackIndex)

        case .sequenceNumber:
            return .relocatedSequenceNumber(trackIndex: trackIndex)

        case .sequenceTrackName:
            return .relocatedSequenceTrackName(trackIndex: trackIndex)

        case .smpteOffset:
            return .relocatedSMPTEOffset(trackIndex: trackIndex)

        default:
            return nil
        }
    }

    private static func _terminate(_ event: SMFEvent) -> SMFEvent {
        switch event {
        case let .sysEx(eventTime, .continuation(dataBytes)):
            .sysEx(eventTime, .continuation(dataBytes + [0xf7]))

        case let .sysEx(eventTime, .systemExclusive(dataBytes)):
            .sysEx(eventTime, .systemExclusive(dataBytes + [0xf7]))

        default:
            event
        }
    }

    // MARK: Private Instance Methods

    // Ensures the track has exactly one End-of-Track event, as its final
    // event. The End-of-Track tick is the latest tick of any event in the
    // track, including any existing End-of-Track: RP-001 (p.9) uses it to give
    // the track an exact length, so a later End-of-Track is never pulled back
    // to the last musical event.
    private mutating func _canonicalizeEndOfTrack(_ events: [SMFEvent],
                                                  at trackIndex: Int) -> SMFTrack {
        let track = SMFTrack(events: events)
        let eotIndices = track.events.indices.filter { track.events[$0].isEndOfTrack }
        let isCanonical = eotIndices.count == 1 && eotIndices[0] == track.events.count - 1

        guard !isCanonical
        else { return track }

        changes.append(eotIndices.isEmpty
                       ? .insertedEndOfTrack(trackIndex: trackIndex)
                       : .relocatedEndOfTrack(trackIndex: trackIndex))

        let eotTime = track.events.map(\.eventTime).max() ?? .zero

        return SMFTrack(events: track.events.filter { !$0.isEndOfTrack } + [.meta(eotTime, .endOfTrack)])
    }

    private mutating func _editTrack(_ track: SMFTrack,
                                     at trackIndex: Int) -> SMFTrack {
        var events = _relocateLeadingEvents(track.events, at: trackIndex)

        events = _terminateSysExMessages(events, at: trackIndex)

        return _canonicalizeEndOfTrack(events, at: trackIndex)
    }

    // Moves every event that belongs with the tempo map out of tracks other
    // than track 0 and into track 0, at its original tick. RP-001 (p.5)
    // requires the tempo map to be the first track of a format 1 file, and
    // (p.8–9) the sequence number and SMPTE offset to be stored with it.
    private mutating func _relocateConductorEvents(_ tracks: [SMFTrack]) -> [SMFTrack] {
        var conductorEvents: [SMFEvent] = []
        var editedTracks = tracks

        for trackIndex in tracks.indices.dropFirst() {
            var trackChanges: [SMFNormalizer.Change] = []

            let remainingEvents = tracks[trackIndex].events.filter { event in
                guard case let .meta(_, message) = event
                else { return true }

                let change: SMFNormalizer.Change

                switch message {
                case .sequenceNumber:
                    change = .relocatedSequenceNumberToFirstTrack(trackIndex: trackIndex)

                case .smpteOffset:
                    change = .relocatedSMPTEOffsetToFirstTrack(trackIndex: trackIndex)

                case .tempo:
                    change = .relocatedTempo(trackIndex: trackIndex)

                case .timeSignature:
                    change = .relocatedTimeSignature(trackIndex: trackIndex)

                default:
                    return true
                }

                if !trackChanges.contains(change) {
                    trackChanges.append(change)
                }

                conductorEvents.append(event)

                return false
            }

            if !trackChanges.isEmpty {
                changes.append(contentsOf: trackChanges)

                editedTracks[trackIndex] = SMFTrack(events: remainingEvents)
            }
        }

        // The moved events go ahead of any End-of-Track at the same tick, so
        // that the End-of-Track only has to move when the track gets longer.
        if !conductorEvents.isEmpty {
            let track0Events = editedTracks[0].events

            editedTracks[0] = SMFTrack(events: track0Events.filter { !$0.isEndOfTrack }
                                       + conductorEvents
                                       + track0Events.filter(\.isEndOfTrack))
        }

        return editedTracks
    }

    // Moves every sequence number, sequence/track name, SMPTE offset, and
    // device name to time zero at the start of the track, ahead of any
    // transmittable event, keeping their relative order. Events already in
    // place are left alone unless another one has to move.
    private mutating func _relocateLeadingEvents(_ events: [SMFEvent],
                                                 at trackIndex: Int) -> [SMFEvent] {
        var leadingChanges: [SMFNormalizer.Change] = []
        var leadingEvents: [SMFEvent] = []
        var otherEvents: [SMFEvent] = []
        var seenTransmittable = false

        for event in events {
            guard let change = Self._leadingEventChange(event, at: trackIndex),
                  case let .meta(eventTime, message) = event
            else {
                seenTransmittable = seenTransmittable || event.isTransmittable

                otherEvents.append(event)

                continue
            }

            if eventTime != .zero || seenTransmittable,
               !leadingChanges.contains(change) {
                leadingChanges.append(change)
            }

            leadingEvents.append(.meta(.zero, message))
        }

        guard !leadingChanges.isEmpty
        else { return events }

        changes.append(contentsOf: leadingChanges)

        return leadingEvents + otherEvents
    }

    // Ensures every system exclusive message ends with 0xF7 (RP-001 p.6). A
    // multi-packet message is still open while its latest packet does not end
    // with 0xF7; it is terminated (by appending 0xF7 to that packet) when the
    // track ends or when any transmittable event other than a continuation
    // packet arrives, since none may appear between packets. A continuation
    // packet with no open message to continue is converted to the escape that
    // a reader would take it for (RP-001 p.7).
    private mutating func _terminateSysExMessages(_ events: [SMFEvent],
                                                  at trackIndex: Int) -> [SMFEvent] {
        var converted = false
        var editedEvents = events
        var openIndex: Int?
        var terminated = false

        for idx in editedEvents.indices {
            switch editedEvents[idx] {
            case let .sysEx(eventTime, .continuation(dataBytes)) where openIndex == nil:
                editedEvents[idx] = .sysEx(eventTime, .escape(dataBytes))
                converted = true

            case let .sysEx(_, message):
                if let open = openIndex,
                   !message.isContinuation {
                    editedEvents[open] = Self._terminate(editedEvents[open])
                    terminated = true
                }

                openIndex = message.isOpenEnded ? idx : nil

            case .midi:
                if let open = openIndex {
                    editedEvents[open] = Self._terminate(editedEvents[open])
                    openIndex = nil
                    terminated = true
                }

            case .meta:
                break
            }
        }

        if let open = openIndex {
            editedEvents[open] = Self._terminate(editedEvents[open])
            terminated = true
        }

        if terminated {
            changes.append(.terminatedSysEx(trackIndex: trackIndex))
        }

        if converted {
            changes.append(.convertedSysExContinuationToEscape(trackIndex: trackIndex))
        }

        return editedEvents
    }
}
