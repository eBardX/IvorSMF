// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorSMF
import Testing

struct SMFValidatorIssueTests {
}

// MARK: -

extension SMFValidatorIssueTests {
    @Test
    func hashable() {
        let set: Set<SMFValidator.Issue> = [.deltaTimeTooLarge(trackIndex: 0),
                                            .deltaTimeTooLarge(trackIndex: 0),
                                            .missingEndOfTrack(trackIndex: 0)]

        #expect(set.count == 2)
    }

    @Test
    func inequality_differentCase() {
        #expect(SMFValidator.Issue.deltaTimeTooLarge(trackIndex: 0) != .missingEndOfTrack(trackIndex: 0))
    }

    @Test
    func inequality_differentTrackIndex() {
        #expect(SMFValidator.Issue.deltaTimeTooLarge(trackIndex: 0) != .deltaTimeTooLarge(trackIndex: 1))
    }

    @Test
    func message_deltaTimeTooLarge() {
        let issue = SMFValidator.Issue.deltaTimeTooLarge(trackIndex: 2)

        #expect(issue.message.contains("2"))
    }

    @Test
    func message_eventAfterEndOfTrack() {
        let issue = SMFValidator.Issue.eventAfterEndOfTrack(trackIndex: 3)

        #expect(issue.message.contains("3"))
    }

    @Test
    func message_eventDataTooLarge() {
        let issue = SMFValidator.Issue.eventDataTooLarge(trackIndex: 8)

        #expect(issue.message.contains("8"))
    }

    @Test
    func message_invalidTrackCount() {
        let issue = SMFValidator.Issue.invalidTrackCount(trackCount: 0,
                                                         format: .format0)

        #expect(issue.message.contains("0"))
    }

    @Test
    func message_missingEndOfTrack() {
        let issue = SMFValidator.Issue.missingEndOfTrack(trackIndex: 4)

        #expect(issue.message.contains("4"))
    }

    @Test
    func message_unencodableText() {
        let issue = SMFValidator.Issue.unencodableText(trackIndex: 9)

        #expect(issue.message.contains("9"))
    }

    @Test
    func trackIndex() {
        #expect(SMFValidator.Issue.deltaTimeTooLarge(trackIndex: 0).trackIndex == 0)
        #expect(SMFValidator.Issue.eventAfterEndOfTrack(trackIndex: 1).trackIndex == 1)
        #expect(SMFValidator.Issue.eventDataTooLarge(trackIndex: 2).trackIndex == 2)
        #expect(SMFValidator.Issue.invalidTrackCount(trackCount: 0,
                                                     format: .format0).trackIndex == nil)
        #expect(SMFValidator.Issue.missingEndOfTrack(trackIndex: 3).trackIndex == 3)
        #expect(SMFValidator.Issue.unencodableText(trackIndex: 7).trackIndex == 7)
    }
}
