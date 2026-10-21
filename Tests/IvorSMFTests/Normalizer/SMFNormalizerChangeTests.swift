// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFNormalizerChangeTests {
}

// MARK: -

extension SMFNormalizerChangeTests {
    @Test
    func hashable() {
        let set: Set<SMFNormalizer.Change> = [.insertedEndOfTrack(trackIndex: 0),
                                              .insertedEndOfTrack(trackIndex: 0),
                                              .relocatedTempo(trackIndex: 0)]

        #expect(set.count == 2)
    }

    @Test
    func inequality_differentCase() {
        #expect(SMFNormalizer.Change.insertedEndOfTrack(trackIndex: 0) != .relocatedTempo(trackIndex: 0))
    }

    @Test
    func message_allCases() {
        #expect(!SMFNormalizer.Change.coercedFormat(from: .format0, to: .format1).message.isEmpty)
        #expect(!SMFNormalizer.Change.convertedSysExContinuationToEscape(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.insertedEndOfTrack(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedDeviceName(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedEndOfTrack(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedSequenceNumber(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedSequenceNumberToFirstTrack(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedSequenceTrackName(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedSMPTEOffset(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedSMPTEOffsetToFirstTrack(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedTempo(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.relocatedTimeSignature(trackIndex: 0).message.isEmpty)
        #expect(!SMFNormalizer.Change.terminatedSysEx(trackIndex: 0).message.isEmpty)
    }

    @Test
    func trackIndex_allCases() {
        #expect(SMFNormalizer.Change.coercedFormat(from: .format0, to: .format1).trackIndex == nil)
        #expect(SMFNormalizer.Change.insertedEndOfTrack(trackIndex: 1).trackIndex == 1)
        #expect(SMFNormalizer.Change.relocatedEndOfTrack(trackIndex: 2).trackIndex == 2)
        #expect(SMFNormalizer.Change.relocatedSequenceNumber(trackIndex: 3).trackIndex == 3)
        #expect(SMFNormalizer.Change.relocatedTempo(trackIndex: 4).trackIndex == 4)
        #expect(SMFNormalizer.Change.relocatedTimeSignature(trackIndex: 5).trackIndex == 5)
        #expect(SMFNormalizer.Change.convertedSysExContinuationToEscape(trackIndex: 6).trackIndex == 6)
        #expect(SMFNormalizer.Change.relocatedDeviceName(trackIndex: 7).trackIndex == 7)
        #expect(SMFNormalizer.Change.relocatedSequenceNumberToFirstTrack(trackIndex: 8).trackIndex == 8)
        #expect(SMFNormalizer.Change.relocatedSequenceTrackName(trackIndex: 9).trackIndex == 9)
        #expect(SMFNormalizer.Change.relocatedSMPTEOffset(trackIndex: 10).trackIndex == 10)
        #expect(SMFNormalizer.Change.relocatedSMPTEOffsetToFirstTrack(trackIndex: 11).trackIndex == 11)
        #expect(SMFNormalizer.Change.terminatedSysEx(trackIndex: 12).trackIndex == 12)
    }
}
