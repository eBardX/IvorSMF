// © 2026 John Gary Pusey (see LICENSE.md)

extension SMFValidator {

    // MARK: Internal Nested Types

    internal struct Checker {

        // MARK: Internal Initializers

        internal init(sequence: SMFSequence) {
            self.issues = []
            self.sequence = sequence
        }

        // MARK: Private Instance Properties

        private let sequence: SMFSequence

        private var issues: [Issue]
    }
}

// MARK: -

extension SMFValidator.Checker {

    // MARK: Internal Instance Methods

    internal mutating func checkSequence() -> [SMFValidator.Issue] {
        _checkTrackCount()

        for (idx, track) in sequence.tracks.enumerated() {
            _checkTrack(track, at: idx)
        }

        return issues
    }

    // MARK: Private Type Properties

    // The maximum value encodable as an SMF variable-length quantity.
    private static let maxVarlen: UInt = 0x0fffffff

    // MARK: Private Instance Methods

    private mutating func _checkEvent(_ event: SMFEvent,
                                      at idx: Int) {
        switch event {
        case let .meta(_, message):
            if let typeByte = message.typeByte,
               typeByte >= 0x80 {
                issues.append(.invalidMetaEventType(trackIndex: idx))
            }

            if message.dataBytes == nil {
                issues.append(.unencodableText(trackIndex: idx))
            } else if let dataBytes = message.dataBytes,
                      UInt(dataBytes.count) > Self.maxVarlen {
                issues.append(.eventDataTooLarge(trackIndex: idx))
            }

        case .midi:
            break

        case let .sysEx(_, message):
            if let dataBytes = message.dataBytes,
               UInt(dataBytes.count) > Self.maxVarlen {
                issues.append(.eventDataTooLarge(trackIndex: idx))
            }
        }
    }

    // RP-001 (p.6–7): every system exclusive message must end with 0xF7, no
    // transmittable event may appear between the packets of a multi-packet
    // message, and a continuation packet must have a message to continue.
    private mutating func _checkSysExPackets(_ track: SMFTrack,
                                             at idx: Int) {
        var isOpen = false
        var hasOrphan = false
        var isUnterminated = false

        for event in track.events {
            switch event {
            case let .sysEx(_, message):
                if message.isContinuation {
                    hasOrphan = hasOrphan || !isOpen
                } else if isOpen {
                    isUnterminated = true
                }

                isOpen = message.isOpenEnded

            case .midi:
                isUnterminated = isUnterminated || isOpen
                isOpen = false

            case .meta:
                break
            }
        }

        if isUnterminated || isOpen {
            issues.append(.unterminatedSysEx(trackIndex: idx))
        }

        if hasOrphan {
            issues.append(.orphanSysExContinuation(trackIndex: idx))
        }
    }

    private mutating func _checkTrack(_ track: SMFTrack,
                                      at idx: Int) {
        if let eotIndex = track.events.firstIndex(where: { $0.isEndOfTrack }) {
            if eotIndex < track.events.count - 1 {
                issues.append(.eventAfterEndOfTrack(trackIndex: idx))
            }
        } else {
            issues.append(.missingEndOfTrack(trackIndex: idx))
        }

        _checkSysExPackets(track, at: idx)

        var previousTime: UInt = 0

        for event in track.events {
            let eventTime = event.eventTime.uintValue

            if eventTime - previousTime > Self.maxVarlen {
                issues.append(.deltaTimeTooLarge(trackIndex: idx))
            }

            previousTime = eventTime

            _checkEvent(event, at: idx)
        }
    }

    private mutating func _checkTrackCount() {
        let trackCount = sequence.tracks.count
        let isValid = (sequence.format == .format0 && trackCount == 1)
            || (sequence.format != .format0 && (1...0xffff).contains(trackCount))

        if !isValid {
            issues.append(.invalidTrackCount(trackCount: trackCount,
                                             format: sequence.format))
        }
    }
}
