import Foundation
import Testing
@testable import QuickCommit

struct ModelScaffoldTests {
    @Test func repositoryRecordHasStableIdentity() {
        let record = RepositoryRecord(displayName: "Example")
        #expect(!record.id.uuidString.isEmpty)
        #expect(record.displayName == "Example")
    }

    @Test(arguments: [0, 2])
    func fallbackMessageIsAvailable(for fileCount: Int) async {
        let message = await FallbackCommitMessageGenerator().subject(for: .init(changedFileCount: fileCount))
        #expect(!message.isEmpty)
    }
}
